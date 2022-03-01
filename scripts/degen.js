const {verify} = require("crypto");
const {BigNumber} = require("ethers");
const {formatEther, parseEther} = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;

const sleep = async (ms) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

// Fantom addresses
const governance = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";
const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
const controller = "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6";
const timelock = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";

const deployAndTest = async () => {
  const contracts = [
    // "src/strategies/fantom/oxd/strategy-oxd-xboo.sol:StrategyOxdXboo",
    // "src/strategies/fantom/oxd/strategy-oxd-xcredit.sol:StrategyOxdXcredit",
    // "src/strategies/fantom/oxd/strategy-oxd-xscream.sol:StrategyOxdXscream",
    "src/strategies/fantom/oxd/strategy-oxd-xtarot.sol:StrategyOxdXtarot",
  ];

  for (const contract of contracts) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);

    try {
      console.log(`Deploying ${contract.substring(contract.lastIndexOf(":") + 1)}...`);

      const strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);
      await strategy.deployTransaction.wait();
      await sleep(5000);

      console.log(`✔️ Strategy deployed at: ${strategy.address}`);

      const want = await strategy.want();
      console.log(`Deploying PickleJar...`);
      const jar = await PickleJarFactory.deploy(want, governance, timelock, controller);
      await jar.deployTransaction.wait();
      await sleep(5000);

      console.log(`✔️ PickleJar deployed at: ${jar.address}`);
      console.log(`Want address is: ${want}`);

      console.log(`Approving want token for deposit...`);
      const wantContract = await ethers.getContractAt("ERC20", want);
      const approveTx = await wantContract.approve(jar.address, ethers.constants.MaxUint256);
      await approveTx.wait();
      console.log(`✔️ Successfully approved Jar to spend want`);

      console.log(`Setting all the necessary stuff in controller...`);

      const approveStratTx = await Controller.approveStrategy(want, strategy.address);
      await approveStratTx.wait();
      await sleep(5000);

      const setJarTx = await Controller.setJar(want, jar.address);
      await setJarTx.wait();
      await sleep(5000);

      const setStratTx = await Controller.setStrategy(want, strategy.address);
      await setStratTx.wait();

      await sleep(5000);

      console.log(`✔️ Controller params all set!`);

      console.log(`Depositing in Jar...`);
      const depositTx = await jar.depositAll();
      await depositTx.wait();
      console.log(`✔️ Successfully deposited want in Jar`);

      console.log(`Calling earn...`);
      const earnTx = await jar.earn();
      await earnTx.wait();
      console.log(`✔️ Successfully called earn`);

      console.log(`Waiting for 30 seconds before harvesting...`);
      await sleep(30000);

      const harvestTx = await strategy.harvest();
      await harvestTx.wait();

      const ratio = await jar.getRatio();
      if (ratio.gt(BigNumber.from(parseEther("1")))) {
        console.log(`✔️ Harvest was successful, ending ratio of ${ratio.toString()}`);
      } else {
        console.log(`❌ Harvest failed, ending ratio of ${ratio.toString()}`);
      }
      console.log(`Verifying contracts...`);
      await hre.run("verify:verify", {
        address: strategy.address,
        constructorArguments: [governance, strategist, controller, timelock],
      });
    } catch (e) {
      console.log(`Oops something went wrong...`);
      console.error(e);
      await sleep(5000);
    }
  }
};

const verifyContracts = async () => {
  const strategies = ["0xab986D3698A952A1b369EaaC7dA80e285CE5519d"];
  for (const strategy of strategies) {
    await hre.run("verify:verify", {
      address: strategy,
      constructorArguments: [governance, strategist, controller, timelock],
    });
  }
};

const main = async () => {
  // await deployAndTest();
  await verifyContracts();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
