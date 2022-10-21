const hre = require("hardhat");
const ethers = hre.ethers;

const deployPickleToken = async () => {
  console.log("deploying pickle token...");

  const childChainManager = "0x195fe6EE6639665CCeB15BCCeB9980FC445DFa0B";
  const minter = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";

  const PickleTokenFactory = await ethers.getContractFactory("src/polygon/pickle-token.sol:PickleToken");
  const PickleToken = await PickleTokenFactory.deploy("PickleToken", "PICKLE", 18, childChainManager, minter);
  console.log("pickle token deployed at ", PickleToken.address);
};

const deployMasterChef = async () => {
  console.log("deploying master chef...");

  const pickle = "0x2b88aD57897A8b496595925F43048301C37615Da";

  const MasterChefFactory = await ethers.getContractFactory("src/polygon/minichefv2.sol:MiniChefV2");
  const MasterChef = await MasterChefFactory.deploy(pickle);
  console.log("minichef deployed at ", MasterChef.address);
  return MasterChef.address;
};

const addJars = async () => {
  const MasterChef = await ethers.getContractFactory("src/polygon/masterchef.sol:MasterChef");

  const masterChef = MasterChef.attach("0xAc7C044e1197dF73aE5F8ec2c1775419b0A248C5");
  // await masterChef.add(1, "0x9eD7e3590F2fB9EEE382dfC55c71F9d3DF12556c", false);
  // await masterChef.add(1, "0x80aB65b1525816Ffe4222607EDa73F86D211AC95", false);
  // await masterChef.add(1, "0x91bcc0BBC2ecA760e3b8A79903CbA53483A7012C", false);
  // await masterChef.add(1, "0x0519848e57Ba0469AA5275283ec0712c91e20D8E", false);
  // await masterChef.add(1, "0x1A602E5f4403ea0A5C06d3DbD22B75d3a2D299D5", false);
  // await masterChef.add(1, "0x80aB65b1525816Ffe4222607EDa73F86D211AC95", false);
  // await masterChef.add(1, "0xd438Ba7217240a378238AcE3f44EFaaaF8aaC75A", false);
  await masterChef.setPicklePerBlock(ethers.utils.parseEther("0.001"));
  const picklePerBlock = await masterChef.picklePerBlock();
  console.log("all jars added!", ethers.utils.formatEther(picklePerBlock));
};

const harvesters = [
  "0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf",
  "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C",
  "0xb4522eB2cA49963De9c3dC69023cBe6D53489C98",
];

const setJar = async () => {
  const governance = "0xf02ceb58d549e4b403e8f85fbbaee4c5dfa47c01";
  const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const timelock = "0xf02ceb58d549e4b403e8f85fbbaee4c5dfa47c01";

  const want = "0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443";

  const tickMultiplier = 235;

  console.log("deploying controller...");

  const ControllerFactory = await ethers.getContractFactory("src/controller-v7.sol:ControllerV7");
  const controller = await ControllerFactory.deploy(governance, strategist, timelock, governance, governance);

  await controller.deployed();
  console.log("controller deployed at: ", controller.address);

  console.log("deploying strategy...");

  const StrategyFactory = await ethers.getContractFactory(
    "src/strategies/arbitrum/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyUsdcEthUniV3Arbi"
  );

  const strategy = await StrategyFactory.deploy(tickMultiplier, governance, strategist, controller.address, timelock);
  await strategy.deployed();

  console.log("strategy deployed at: ", strategy.address);

  const whitelistTx = await strategy.whitelistHarvesters(harvesters);
  await whitelistTx.wait();

  console.log("Whitelisted harvesters");

  console.log("deploying jar...");

  let jarDescrip = `pickling USDC/WETH Jar`;
  let pTokenName = `pUSDCWETH`;

  const PickleJarFactory = await ethers.getContractFactory("src/arbitrum/pickle-jar-univ3.sol:PickleJarUniV3Arbitrum");
  const jar = await PickleJarFactory.deploy(jarDescrip, pTokenName, want, governance, timelock, controller.address);

  await jar.deployed();
  console.log("Jar deployed at: ", jar.address);

  await Promise.all([
    hre.run("verify:verify", {
      address: controller.address,
      constructorArguments: [governance, strategist, timelock, governance, governance],
    }),
    hre.run("verify:verify", {
      address: strategy.address,
      constructorArguments: [tickMultiplier, governance, strategist, controller.address, timelock],
    }),
    hre.run("verify:verify", {
      address: jar.address,
      constructorArguments: [jarDescrip, pTokenName, governance, timelock, controller.address],
    }),
  ]);
};

const approveBal = async () => {
  const lpToken = "0x64541216bafffeec8ea535bb71fbc927831d0595";
  const jar = "0x0be790c83648c28eD285fee5E0BD79D1d57AAe69";
  const ERC20 = await ethers.getContractAt("src/lib/erc20.sol:ERC20", lpToken);

  const deployer = new ethers.Wallet(process.env.MNEMONIC, ethers.provider);
  console.log("approving...");
  await ERC20.connect(deployer).approve(jar, ethers.constants.MaxUint256);
  console.log("success!");
};

const main = async () => {
  // await deployPickleToken();
  // await deployMasterChef();
  // await handOverPermsToMasterChef();
  // await deployTimelock();
  // await deployControllerV4();
  // await deployComethWmaticMustStrategy();
  // await deployPickleJar();
  // await deployPickleJar();
  await setJar();
  // await approveBal();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
