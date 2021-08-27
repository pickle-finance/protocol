// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const iceQueenAddr = "0xB12531a2d758c7a8BF09f44FC88E646E1BF9D375";
  const userAddr = "0xdbc195a0ED72c0B059f8906e97a90636d2B6409F";

  const pngAvaxAaveE = "0x7F8E7a8Bd63A113B202AE905877918Fb9cA13091";
  const snobAddr = "0xC38f41A296A4493Ff429F1238e030924A1542e50";

  const s4D = "0xB91124eCEF333f17354ADD2A8b944C76979fE3EC";

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [governanceAddr],
  });

  const governanceSigner = ethers.provider.getSigner(governanceAddr);
  const userSigner = ethers.provider.getSigner(userAddr);
  const iceQueen = await ethers.getContractAt(
    "contracts/yield-farming/icequeen.sol:IceQueen",
    iceQueenAddr,
    governanceSigner
  );
  iceQueen.connect(governanceSigner);

  console.log("-- Deploying GaugeProxy contract --");
  const GaugeProxyV2 = await hre.ethers.getContractFactory("GaugeProxyV2");
  const gaugeProxy = await GaugeProxyV2.deploy();
  await gaugeProxy.deployed();

  const mSNOWCONESAddr = await gaugeProxy.TOKEN();
  console.log(`GaugeProxy deployed at ${gaugeProxy.address}`);

  console.log("-- Adding mSNOWCONES to iceQueen --");
  let populatedTx;
  populatedTx = await iceQueen.populateTransaction.add(
    5000000,
    mSNOWCONESAddr,
    false,
    { gasLimit: 9000000 }
  );
  await governanceSigner.sendTransaction(populatedTx);

  console.log("-- Adding pngAvaxAaveE Gauge --");
  await gaugeProxy.addGauge(pngAvaxAaveE);

  console.log("-- Adding s4D Gauge --");
  await gaugeProxy.addGauge(s4D);

  console.log("-- impersonating User --");
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [userAddr],
  });

  console.log("SNOWCONE: ",await gaugeProxy.SNOWCONE());

  const gaugeProxyFromUser = gaugeProxy.connect(userAddr);
  console.log("-- Voting on pngAvaxAaveE with 60% weight --");
  populatedTx = await gaugeProxyFromUser.populateTransaction.vote(
    [pngAvaxAaveE, s4D],
    [6000000, 4000000],
    {
      gasLimit: 9000000,
    }
  );
  await userSigner.sendTransaction(populatedTx);
  const pid = (await iceQueen.poolLength()) - 1;
  await gaugeProxy.setPID(pid);
  await gaugeProxy.deposit();

  console.log("-- Wait for 10 blocks to be mined --");
  for (let i = 0; i < 10; i++) {
    await hre.network.provider.request({
      method: "evm_mine",
    });
  }

  console.log("-- Pre Distribute SNOB to gauges --");
  await gaugeProxy.preDistribute();
  console.log("-- Distribute SNOB to gauges --");
  await gaugeProxy.distribute(0,2);

  const pglGaugeAddr = await gaugeProxy.getGauge(pngAvaxAaveE);
  const s4DGaugeAddr = await gaugeProxy.getGauge(s4D);
  const snob = await ethers.getContractAt("Snowball", snobAddr);

  const snobRewards = await snob.balanceOf(pglGaugeAddr);
  console.log("rewards to pngAvaxAaveE gauge", snobRewards);

  const s4DRewards = await snob.balanceOf(s4DGaugeAddr);
  console.log("rewards to s4D gauge", s4DRewards);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });