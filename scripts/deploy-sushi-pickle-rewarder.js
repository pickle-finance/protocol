const hre = require("hardhat");
const ethers = hre.ethers;

const deployPickleRewarder = async () => {
  console.log("deploying PickleRewarder...");

  const pickle = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
  const masterchefv2 = "0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d";

  const PickleRewarderFactory = await ethers.getContractFactory(
    "src/sushi-pickle-rewarder/pickle-rewarder.sol:PickleRewarder"
  );
  const PickleRewarder = await PickleRewarderFactory.deploy(
    pickle,
    0,
    masterchefv2
  );
  console.log("PickleRewarder deployed at ", PickleRewarder.address);
};

const main = async () => {
  await deployPickleRewarder();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
