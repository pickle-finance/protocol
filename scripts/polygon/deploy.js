const hre = require("hardhat");
const ethers = hre.ethers;

const deployPickleToken = async () => {
  console.log("deploying pickle token...");

  const childChainManager = "0x195fe6EE6639665CCeB15BCCeB9980FC445DFa0B";
  const minter = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";

  const PickleTokenFactory = await ethers.getContractFactory(
    "src/polygon/pickle-token.sol:PickleToken"
  );
  const PickleToken = await PickleTokenFactory.deploy(
    "PickleToken",
    "PICKLE",
    18,
    childChainManager,
    minter
  );
  console.log("pickle token deployed at ", PickleToken.address);
};

const deployMasterChef = async () => {
  console.log("deploying master chef...");

  const pickle = "0x2b88aD57897A8b496595925F43048301C37615Da";

  const MasterChefFactory = await ethers.getContractFactory(
    "src/polygon/minichefv2.sol:MiniChefV2"
  );
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

const deployComethWmaticMustStrategy = async () => {
  console.log("Mai: miMATIC/USDC deploying strategy...");

  const governance = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const strategist = "0x88d226A9FC7485Ae0856AE51C3Db15d7ad242a3f";
  const controller = "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09";
  const timelock = "0x63A991b9c34D2590A411584799B030414C9b0D6F";

  const StrategyComethWmaticMustLpV4Factory = await ethers.getContractFactory(
    "src/flatten/strategy-mai-mimatic-usdc-lp.sol:StrategyMaiMiMaticUsdcLp"
  );
  const StrategyComethWmaticMustLpV4 = await StrategyComethWmaticMustLpV4Factory.deploy(
    governance,
    strategist,
    controller,
    timelock
  );
  console.log("Mai: miMATIC/USDC strategy deployed at ", StrategyComethWmaticMustLpV4.address);
};

const deployPickleJar = async () => {
  let governance, strategist, timelock, devfund, treasury;
  governance =
    strategist =
    timelock =
    devfund =
    treasury =
      "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";
  const harvesters = [
    "0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf",
    "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C",
    "0xb4522eB2cA49963De9c3dC69023cBe6D53489C98",
  ];

  // console.log("deploying Controller Proxy...");
  // const AdminFactory = await ethers.getContractFactory("src/Proxy/ProxyAdmin.sol:ProxyAdmin")
  // const admin = await AdminFactory.deploy()
  // await admin.deployed();

  // console.log("Admin deployed at: ", admin.address);

  const controller = await ethers.getContractAt("src/controller-v6.sol:ControllerV6", "0xD6CA5052Bf7b57f6AEdeE0D259a0E9AA4DCa64c6");
  // console.log("deploying Controller Proxy...");

  // const ProxyFactory = await ethers.getContractFactory("src/Proxy/AdminUpgradeabilityProxy.sol:AdminUpgradeabilityProxy")
  // const proxy = await ProxyFactory.deploy(imp.address, admin.address, [])
  // await proxy.deployed();

  // console.log("Proxy deployed at: ", proxy.address);

  console.log("deploying Pickle Jar...");

  const RBN_ETH_POOL = "0x94981F69F7483AF3ae218CbfE65233cC3c60d93a";

  const PickleJarFactory = await ethers.getContractFactory(
    "src/pickle-jar-univ3.sol:PickleJarUniV3"
  );
  const pickleJar = await PickleJarFactory.deploy(
    "pickling Uni v3 RBN/ETH",
    "pUniV3",
    RBN_ETH_POOL,
    -887200,
    887200,
    governance,
    timelock,
    controller.address
  );
  await pickleJar.deployed();
  console.log("✅ PickleJar deployed at: ", pickleJar.address);

  console.log("Deploying RBN/ETH strategy...");

  const StrategyFactory = await ethers.getContractFactory(
    "src/strategies/ribbon/strategy-rbn-eth-univ3.sol:StrategyRbnEthUniV3"
  );

  const strategy = await StrategyFactory.deploy(
    governance,
    strategist,
    controller.address,
    timelock
  );

  console.log("✅ RBN/ETH strategy deployed at: ", strategy.address);

  console.log("Approving/setting strategy on controller...");
  const deployer = new ethers.Wallet(process.env.MNEMONIC, ethers.provider);

  await controller.connect(deployer).setJar(RBN_ETH_POOL, pickleJar.address);
  await controller.connect(deployer).approveStrategy(RBN_ETH_POOL, strategy.address);
  await controller.connect(deployer).setStrategy(RBN_ETH_POOL, strategy.address);

  console.log("✅ Addresses successfully set on Controller");
  console.log("Whitelisting harvesters on strategy...");
  await strategy.whitelistHarvesters(harvesters);
  console.log("✅ Harvesters whitelisted");
};

const setJar = async () => {
  const want = "0x1Edb2D8f791D2a51D56979bf3A25673D6E783232";
  const controller = "0x254825F93e003D6e575636eD2531BAA948d162dd";
  const picklejar = "0x9eD7e3590F2fB9EEE382dfC55c71F9d3DF12556c";

  const ControllerV4 = await ethers.getContractAt(
    "src/flatten/controller-v4.sol:ControllerV4",
    controller
  );

  const strategy = "0x51cF19A126E642948B5c5747471fd722B2EdCa25";

  const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY, ethers.provider);

  console.log("setJar");
  await ControllerV4.connect(deployer).setJar(want, picklejar);
  // this should be done on governance,
  // console.log("approveStrategy");
  // await ControllerV4.connect(deployer).approveStrategy(want, strategy);
  // console.log("setStrategy");
  // await ControllerV4.connect(deployer).setStrategy(want, strategy);
};

const main = async () => {
  // await deployPickleToken();
  // await deployMasterChef();
  // await handOverPermsToMasterChef();
  // await deployTimelock();
  // await deployControllerV4();
  // await deployComethWmaticMustStrategy();
  await deployPickleJar();
  // await setJar();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
