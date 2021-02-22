// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
  const masterChefAddr = "0xbD17B1ce622d73bD438b9E658acA5996dc394b0d";
  const userAddr = "0x1CbF903De5D688eDa7D6D895ea2F0a8F2A521E99";

  const pickleLP = "0xdc98556Ce24f007A5eF6dC1CE96322d65832A819";
  const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [governanceAddr],
  });

  const governanceSigner = ethers.provider.getSigner(governanceAddr);
  const userSigner = ethers.provider.getSigner(userAddr);
  const masterChef = await ethers.getContractAt(
    "src/yield-farming/masterchef.sol:MasterChef",
    masterChefAddr,
    governanceSigner
  );
  masterChef.connect(governanceSigner);

  console.log("-- Deploying GaugeProxy contract --");
  const GaugeProxy = await hre.ethers.getContractFactory("GaugeProxy");
  const gaugeProxy = await GaugeProxy.deploy();
  await gaugeProxy.deployed();

  const mDILLAddr = await gaugeProxy.TOKEN();
  console.log(`GaugeProxy deployed at ${gaugeProxy.address}`);

  console.log("-- Adding mDILL to MasterChef --");
  let populatedTx;
  populatedTx = await masterChef.populateTransaction.add(
    5000000,
    mDILLAddr,
    false,
    { gasLimit: 9000000 }
  );
  await governanceSigner.sendTransaction(populatedTx);

  console.log("-- Adding PICKLE LP Gauge --");
  await gaugeProxy.addGauge(pickleLP);

  console.log("-- Voting on LP Gauge with 100% weight --");
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [userAddr],
  });
  const gaugeProxyFromUser = gaugeProxy.connect(userAddr);
  populatedTx = await gaugeProxyFromUser.populateTransaction.vote(
    [pickleLP],
    [10000000],
    {
      gasLimit: 9000000,
    }
  );
  await userSigner.sendTransaction(populatedTx);
  const pidDill = (await masterChef.poolLength()) - 1;
  await gaugeProxy.setPID(pidDill);
  await gaugeProxy.deposit();

  console.log("-- Wait for 10 blocks to be mined --");
  for (let i = 0; i < 10; i++) {
    await hre.network.provider.request({
      method: "evm_mine",
    });
  }

  console.log("-- Distribute PICKLE to gauges --");
  await gaugeProxy.distribute();

  const gaugeAddr = await gaugeProxy.getGauge(pickleLP);
  const pickle = await ethers.getContractAt("PickleToken", pickleAddr);

  const rewards = await pickle.balanceOf(gaugeAddr);
  console.log(rewards);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
