const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat");
const ethers = hre.ethers;

const deployAm3crvStrategy = async () => {
  console.log("Curve: am3crv deploying strategy...");

  const governance = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
  const strategist = "0x88d226A9FC7485Ae0856AE51C3Db15d7ad242a3f";
  const controller = "0x254825F93e003D6e575636eD2531BAA948d162dd";
  const timelock = "0x63A991b9c34D2590A411584799B030414C9b0D6F";

  const StrategyCurveAm3CRVv2Factory = await ethers.getContractFactory(
    "src/flatten/strategy-curve-am3crv-v2.sol:StrategyCurveAm3CRVv2"
  );
  const StrategyCurveAm3CRVv2 = await StrategyCurveAm3CRVv2Factory.deploy(
    governance,
    strategist,
    controller,
    timelock
  );
  console.log(
    "Curve: am3crv strategy deployed at ",
    StrategyCurveAm3CRVv2.address
  );
};

const deployPickleJar = async () => {
  console.log("deploying PickleJar...");

  const want = "0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171"; // am3crv lp
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
  const want = "0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171"; // am3crv lp
  const controller = "0x254825F93e003D6e575636eD2531BAA948d162dd";
  const picklejar = "0xA6c8AAA4Ae98777A751270E9053fDCaAacF97a6a";

  const ControllerV4 = await ethers.getContractAt(
    "src/flatten/controller-v4.sol:ControllerV4",
    controller
  );

  const strategy = "0xa0b1cd46141ED490A5Fa66755F3d1013B920602C";

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
  // await deployAm3crvStrategy();
  // await deployPickleJar();
  await setJar();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
