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
const deployPickleJar = async () => {
  console.log("deploying Strategy...");

  const governance = "0x9d074E37d408542FD38be78848e8814AFB38db17";
  const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const controller = "0x6847259b2B3A4c17e7c43C54409810aF48bA5210";
  const timelock = "0xd92c7faa0ca0e6ae4918f3a83d9832d9caeaa0d3";

  const want = "0x1054Ff2ffA34c055a13DCD9E0b4c0cA5b3aecEB9";

  const StrategyFactory = await ethers.getContractFactory(
    "src/strategies/convex/strategy-convex-cadc-usdc-lp.sol:StrategyConvexCadcUsdc"
  );
  const strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);

  await strategy.deployed();
  console.log("Strategy deployed at ", strategy.address);

  const JarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
  const jar = await JarFactory.deploy(want, governance, timelock, controller);
  await jar.deployed();
  console.log("Jar deployed at ", jar.address);

  await hre.run("verify:verify", {
    address: strategy.address,
    constructorArguments: [governance, strategist, controller, timelock],
  });
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

const query = async () => {
  const contract = await ethers.getContractAt("IUwuLend", "0x2409aF0251DCB89EE3Dee572629291f9B087c668");
  const dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

  const reserveData = await contract.getReserveData(dai);
  console.log({reserveData});
  const addressProviderAddr = await contract.getAddressesProvider();

  const addressProvider = await ethers.getContractAt(
    ["function getAddress(bytes32) public view returns (address)"],
    addressProviderAddr
  );

  const providerAddr = await addressProvider.getAddress(
    "0x0100000000000000000000000000000000000000000000000000000000000000"
  );
  console.log(providerAddr);

  const providerContract = await ethers.getContractAt("IDataProvider", providerAddr);

  const configurationData = await providerContract.getReserveConfigurationData(dai);
  console.log({configurationData});
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
  // await setJar();
  // await approveBal();
  await query();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
