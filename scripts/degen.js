const {BigNumber} = require("ethers");
const {formatEther, parseEther} = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;

const sleep = async (ms) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

const deployAndTest = async () => {
  const governance = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const timelock = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const controller = "0x95ca4584ea2007d578fa2693ccc76d930a96d165";

  const strategies = [
    "src/strategies/moonbeam/solarflare/strategy-solareflar-glmr-movr-lp.sol:StrategyFlareGlmrMovrLp",
    "src/strategies/moonbeam/solarflare/strategy-solarflare-glmr-wbtc-lp.sol:StrategyFlareGlmrWbtc",
    "src/strategies/moonbeam/solarflare/strategy-solarflare-glmr-usdc-lp.sol:StrategyFlareGlmrUsdcLp",
    "src/strategies/moonbeam/solarflare/strategy-solarflare-glmr-eth-lp.sol:StrategyFlareGlmrEthLp"
  ];

  await Promise.all(
    strategies.map(async (contract) => {
      const StrategyFactory = await ethers.getContractFactory(contract);
      const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
      const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);

      try {
        console.log(`Deploying ${contract.substring(contract.lastIndexOf(":") + 1)}...`);

        const strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);
        console.log(`✔️ Strategy deployed at: ${strategy.address}`);
        const want = await strategy.want();
        const want = "0x976888647affb4b2d7Ac1952cB12ca048cD67762";

        console.log(`Deploying PickleJar...`);
        const jar = await PickleJarFactory.deploy(want, governance, timelock, controller);
        console.log(`✔️ PickleJar deployed at: ${jar.address}`);

        console.log(`Approving want token for deposit...`);
        const wantContract = await ethers.getContractAt("ERC20", want);
        const approveTx = await wantContract.approve(jar.address, ethers.constants.MaxUint256);
        await approveTx.wait();
        console.log(`✔️ Successfully approved Jar to spend want`);

        console.log(`Setting all the necessary stuff in controller...`);

        const approveStratTx = await Controller.approveStrategy(want, strategy.address);
        await approveStratTx.wait();
        const setStratTx = await Controller.setStrategy(want, strategy.address);
        await setStratTx.wait();
        const setJarTx = await Controller.setJar(want, jar.address);
        await setJarTx.wait();

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

        const ratio = await jar.ratio();
        if (ratio.gt(BigNumber.from(parseEther("1")))) {
          console.log(`✔️ Harvest was successful, ending ratio of ${ratio.toString()}`);
          console.log(`Verifying contracts...`);
          await hre.run("verify:verify", {
            address: strategy.address,
            constructorArguments: [governance, strategist, controller, timelock],
          });
        } else {
          console.log(`❌ Harvest failed, ending ratio of ${ratio.toString()}`);
        }
      } catch (e) {
        console.log(`Oops something went wrong...`);
        console.error(e);
      }
    })
  );
};

const main = async () => {
  await deployAndTest();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
