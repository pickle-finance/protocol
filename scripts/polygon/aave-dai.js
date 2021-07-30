const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat");
const ethers = hre.ethers;

const deployAaveDaiStrategy = async () => {
  console.log("Aave: DAI deploying strategy...");

  const governance = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const strategist = "0x88d226A9FC7485Ae0856AE51C3Db15d7ad242a3f";
  const controller = "0x254825F93e003D6e575636eD2531BAA948d162dd";
  const timelock = "0x63A991b9c34D2590A411584799B030414C9b0D6F";

  const StrategyAaveDaiV3Factory = await ethers.getContractFactory(
    "src/flatten/strategy-aave-dai-v3.sol:StrategyAaveDaiV3"
  );
  const StrategyAaveDaiV3 = await StrategyAaveDaiV3Factory.deploy(
    governance,
    strategist,
    controller,
    timelock
  );
  console.log("Aave: DAI strategy deployed at ", StrategyAaveDaiV3.address);
};

const deployPickleJar = async () => {
  console.log("deploying PickleJar...");

  const want = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"; // DAI
  const governance = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const timelock = "0x63A991b9c34D2590A411584799B030414C9b0D6F";
  const controller = "0x254825F93e003D6e575636eD2531BAA948d162dd";

  const PickleJarFactory = await ethers.getContractFactory(
    "src/flatten/pickle-jar.sol:PickleJar"
  );
  const PickleJar = await PickleJarFactory.deploy(
    want,
    governance,
    timelock,
    controller
  );
  console.log("PickleJar deployed at ", PickleJar.address);
};

const setJar = async () => {
  const want = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"; // DAI
  const controller = "0x254825F93e003D6e575636eD2531BAA948d162dd";
  const picklejar = "0x9eD7e3590F2fB9EEE382dfC55c71F9d3DF12556c";

  const ControllerV4 = await ethers.getContractAt(
    "src/flatten/controller-v4.sol:ControllerV4",
    controller
  );

  const strategy = "0x51cF19A126E642948B5c5747471fd722B2EdCa25";

  const deployer = new ethers.Wallet(
    process.env.DEPLOYER_PRIVATE_KEY,
    ethers.provider
  );

  console.log("setJar");
  await ControllerV4.connect(deployer).setJar(want, picklejar);
  // this should be done on governance,
  // console.log("approveStrategy");
  // await ControllerV4.connect(deployer).approveStrategy(want, strategy);
  // console.log("setStrategy");
  // await ControllerV4.connect(deployer).setStrategy(want, strategy);
};

const main = async () => {
  // await deployAaveDaiStrategy();
  // await deployPickleJar();
  await setJar();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
