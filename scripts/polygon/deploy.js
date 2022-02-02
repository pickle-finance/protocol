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

const whitelistHarvesters = async () => {
  strategies = [
    "0x6A0F350715BAAdcC91F29b7e5915f34fc584f53c",
    "0x26839349247324376A8F52f0B6C8155345C5daA8",
    "0x863b32B1443C6719663ffbc88a09BB681d45ed41",
    "0xEB67eA91aAbC4B2efe8cCDBdc85396dC9481b6be",
    "0x964fD1153058B07453386061325391D2F84Af907",
    "0xc2F1Fe87118dC4D35ABEafB55204bb900Ad93ed0",
    "0xdFC22a3F2B76D2039c8C8883653C50BbBc7b12b4",
    "0x826a9cD66A20Ff4c2dC7AAcfa3e413dfee6a71E4",
    "0x7C29dcC491C0A978B31fbdFac453E1Fc9b651a42",
    "0xFdB584F0A0aB9bfA06Ee534a9081FcfBE4De12CB",
    "0x7b8139Fb52C12e28831aDacCC205a6fA1a5A1afb",
    "0x627c32F07C4C789c0FB2A7853aF7085aF653D8b3",
    "0x406D931162ccCA5feACE185Df198E85BD2906040",
    "0x2f1e21Ea0DD575567476599f5f6510DC624Bda3d",
    "0x964075a7eb21C099DC1D9F987eDDF02CE2401F69",
  ];

  for (let i = 0; i < strategies.length; i++) {
    console.log(`Whitelisting ${strategies[i]}...`);
    const strategy = await ethers.getContractAt(
      "src/strategies/looksrare/strategy-looks-eth-lp.sol:StrategyLooksEthLp",
      strategies[i]
    );
    const tx = await strategy.whitelistHarvesters(harvesters);
    await tx.wait();
    console.log("Successfully whitelisted");
  }
};

const deployPickleJar = async () => {
  console.log("deploying Strategy...");

  const governance = "0xf02CeB58d549E4b403e8F85FBBaEe4c5dfA47c01";
  const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const controller = "0x55d5bcef2bfd4921b8790525ff87919c2e26bd03";
  const timelock = "0xf02CeB58d549E4b403e8F85FBBaEe4c5dfA47c01";

  const StrategyFactory = await ethers.getContractFactory(
    "src/strategies/arbitrum/dodo/strategy-dodo-hnd-eth-lp-v3.sol:StrategyDodoHndEthLpV3"
  );
  const strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);

  console.log("Strategy deployed at ", strategy.address);
};

const setJar = async () => {
  const governance = "0x9796b1FA0DE058877a3235e6b1beB9C1f945d99c";

  const want = "0x167384319B41F7094e62f7506409Eb38079AbfF8";

  const controller = "0xE8bf268Df27833f984280d45861eB96D9C440a88";

  console.log("deploying strategy...");

  const StrategyFactory = await ethers.getContractFactory(
    "src/strategies/polygon/uniswapv3/strategy-univ3-matic-eth-lp.sol:StrategyMaticEthUniV3Poly"
  );

  const strategy = await StrategyFactory.deploy(100, governance, governance, controller, governance);
  await strategy.deployed();

  console.log("strategy deployed at: ", strategy.address);

  console.log("deploying jar...");

  const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar-univ3.sol:PickleJarUniV3");
  const jar = PickleJarFactory.deploy("pickling MATIC/ETH Jar", "pMATICETH", want, governance, governance, controller);

  await jar.deployed();
  console.log("Jar deployed at: ", jar.address);
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
  await deployPickleJar();
  // await setJar();
  // await approveBal();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
