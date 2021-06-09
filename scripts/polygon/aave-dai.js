const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat");
const ethers = hre.ethers;

const deployAaveDaiStrategy = async () => {
  console.log("Aave: DAI deploying strategy...");

  const governance = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const strategist = "0x88d226A9FC7485Ae0856AE51C3Db15d7ad242a3f";
  const controller = "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09";
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
  const controller = "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09";

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
  const controller = "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09";
  const picklejar = "0x0519848e57Ba0469AA5275283ec0712c91e20D8E";

  const ControllerV4 = await ethers.getContractAt(
    "src/flatten/controller-v4.sol:ControllerV4",
    controller
  );

  const strategy = "0x0b198b5EE64aB29c98A094380c867079d5a1682e";

  const deployer = new ethers.Wallet(
    process.env.DEPLOYER_PRIVATE_KEY,
    ethers.provider
  );

  await ControllerV4.connect(deployer).setJar(want, picklejar);
  console.log("setJar");
  // this should be done on governance,
  // console.log("approveStrategy");
  // await ControllerV4.connect(deployer).approveStrategy(want, strategy);
  // console.log("setStrategy");
  // await ControllerV4.connect(deployer).setStrategy(want, strategy);
};

const main = async () => {
  await deployAaveDaiStrategy();
  // await deployPickleJar();
  // await setJar();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
