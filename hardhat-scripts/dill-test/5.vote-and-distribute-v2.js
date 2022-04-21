// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const {ethers, upgrades} = require("hardhat");

async function main() {
  const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
  const masterChefAddr = "0xbD17B1ce622d73bD438b9E658acA5996dc394b0d";
  const userAddr = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";

  const pickleLP = "0xdc98556Ce24f007A5eF6dC1CE96322d65832A819";
  const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";

  const pyveCRVETH = "0x5eff6d166d66bacbc1bf52e2c54dd391ae6b1f48";

  await hre.network.provider.request({
    method: "evm_unlockUnknownAccount",
    params: [governanceAddr],
  });
  console.log("impersonation gov");
  const governanceSigner = ethers.provider.getSigner(governanceAddr);
  const userSigner = ethers.provider.getSigner(userAddr);
  const masterChef = await ethers.getContractAt(
    "src/yield-farming/masterchef.sol:MasterChef",
    masterChefAddr,
    governanceSigner
  );
  masterChef.connect(governanceSigner);

  console.log("-- Deploying GaugeProxy v2 contract --");
  const gaugeProxyV2 = await ethers.getContractFactory("/src/dill/gauge-proxy-v2.sol:GaugeProxyV2");
  console.log("Deploying GaugeProxyV2...");
  const GaugeProxyV2 = await upgrades.deployProxy(gaugeProxyV2, [Date.now()], {
    initializer: "initialize",
  });
  await GaugeProxyV2.deployed();
  console.log("GaugeProxyV2 deployed to:", GaugeProxyV2.address);
  const mDILLAddr = await GaugeProxyV2.TOKEN();

  console.log("-- Adding mDILL to MasterChef --");
  let populatedTx;
  populatedTx = await masterChef.populateTransaction.add(
    5000000,
    mDILLAddr,
    false
    // { gasLimit: 9000000 }
  );
  await governanceSigner.sendTransaction(populatedTx);

  console.log("-- Adding PICKLE LP Gauge --");
  await GaugeProxyV2.addGauge(pickleLP);

  console.log("-- Adding pyveCRVETH Gauge --");
  await GaugeProxyV2.addGauge(pyveCRVETH);

  console.log("-- Voting on LP Gauge with 100% weight --");

  await hre.network.provider.request({
    method: "evm_unlockUnknownAccount",
    params: [userAddr],
  });
  console.log("impersonating user");
  const gaugeProxyFromUser = GaugeProxyV2.connect(userAddr);
  populatedTx = await gaugeProxyFromUser.populateTransaction.vote([pickleLP, pyveCRVETH], [6000000, 4000000], {
    gasLimit: 900000,
  });
  await userSigner.sendTransaction(populatedTx);
  console.log("voted");
  const pidDill = (await masterChef.poolLength()) - 1;
  await GaugeProxyV2.setPID(pidDill);
  await GaugeProxyV2.deposit();

  console.log("-- Wait for 10 blocks to be mined --");
  for (let i = 0; i < 10; i++) {
    await hre.network.provider.request({
      method: "evm_mine",
    });
  }
  console.log("-- Wait 7 days to accumulate");
  await hre.network.provider.request({
    method: "evm_increaseTime",
    params: [3600 * 24 * 7],
  });
  await hre.network.provider.request({
    method: "evm_mine",
  });

  await hre.network.provider.request({
    method: "evm_unlockUnknownAccount",
    params: [governanceAddr],
  });

  console.log("-- Distribute PICKLE to gauges --");
  await GaugeProxyV2.distribute(0,1);

  const pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
  const yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);
  // const pickle = await ethers.getContractAt("PickleToken", pickleAddr);
  const pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);
  const pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
  console.log("rewards to Pickle gauge", pickleRewards);

  const yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
  console.log("rewards to pyveCRV gauge", yvecrvRewards);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
