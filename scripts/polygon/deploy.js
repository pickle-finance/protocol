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
  
  const pickle = "0x2b88aD57897A8b496595925F43048301C37615Da";

  const MasterChefFactory = await ethers.getContractFactory("src/polygon/minichefv2.sol:MiniChefV2");
  const MasterChef = await MasterChefFactory.deploy(
    pickle);
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

const deployRewarder = async () => {
  const wmatic = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
const rewardPerSecond = 0;
const minichef = "0x20b2a3fc7b13ca0ccf7af81a68a14cb3116e8749";

const RewarderFactory = await ethers.getContractFactory("src/polygon/PickleRewarder.sol:PickleRewarder");
  const Rewarder = await RewarderFactory.deploy(
    wmatic, rewardPerSecond, minichef);
  console.log("minichef deployed at ", Rewarder.address);
  return Rewarder.address;
}

const main = async () => {
  await deployRewarder();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });