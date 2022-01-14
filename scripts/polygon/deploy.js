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

const setJar = async () => {
  const governance = "0xEae55893cC8637c16CF93D43B38aa022d689Fa62";
  const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const controller = "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09";
  const timelock = "0xEae55893cC8637c16CF93D43B38aa022d689Fa62";

  const wants = [
    "0x91670a2A69554c61d814CD7f406D7793387E68Ef",
    "0x2E7d6490526C7d7e2FDEa5c6Ec4b0d1b9F8b25B7",
    "0x426a56F6923c2B8A488407fc1B38007317ECaFB1",
    "0xaBEE7668a96C49D27886D1a8914a54a5F9805041",
  ];

  const factories = [
    "src/strategies/polygon/raider/strategy-aurum-matic-lp.sol:StrategyAurumMaticLp",
    "src/strategies/polygon/raider/strategy-raider-matic-lp.sol:StrategyRaiderMaticLp",
    "src/strategies/polygon/raider/strategy-raider-weth-lp.sol:StrategyRaiderWethLp",
    "src/strategies/polygon/raider/stratgy-aurum-usdc-lp.sol:StrategyAurumUsdcLp",
  ];
  for (let i = 0; i < wants.length; i++) {
    const StrategyFactory = await ethers.getContractFactory(factories[i]);
    console.log(`deploying strategy for want: ${wants[i]} ....`);
    const strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);
    await strategy.deployed();
    console.log("strategy deployed at: ", strategy.address);

    console.log("deploying le jar");
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const PickleJar = await PickleJarFactory.deploy(wants[i], governance, timelock, controller);

    await PickleJar.deployed();
    console.log("Jar deployed at: ", PickleJar.address);

    await hre.run("verify:verify", {
      address: strategy.address,
      constructorArguments: [governance, strategist, controller, timelock],
    });
  }
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
  await setJar();
  // await approveBal();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
