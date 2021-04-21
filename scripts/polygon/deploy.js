const hre = require("hardhat");
const ethers = hre.ethers;

const deployPickleToken = async () => {
  console.log("deploying pickle token...");

  const childChainManager = "0x195fe6EE6639665CCeB15BCCeB9980FC445DFa0B";
  const minter = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";

  const PickleTokenFactory = await ethers.getContractFactory("src/polygon/pickle-token.sol:PickleToken");
  const PickleToken = await PickleTokenFactory.deploy(
    "PickleToken", "PICKLE", 18, childChainManager, minter
  );
  console.log("pickle token deployed at ", PickleToken.address);
};

const deployMasterChef = async () => {
  console.log("deploying master chef...");
  
  const pickle = "0x835804CC589E07FBbbCE7B8c830F219Dac407F63";
  const devaddr = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";
  const picklePerBlock = 1000000000000;
  const startBlock = 13560000;
  const bonusEndBlock = 0;

  const MasterChefFactory = await ethers.getContractFactory("src/polygon/masterchef.sol:MasterChef");
  const MasterChef = await MasterChefFactory.deploy(
    pickle, devaddr, picklePerBlock, startBlock, bonusEndBlock
  );
  console.log("master chef deployed at ", MasterChef.address);
};

const main = async () => {
  // await deployPickleToken();
  await deployMasterChef();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });