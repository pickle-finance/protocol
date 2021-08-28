// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {

  // CONSTANTS ///////////////////////////////////////////////////////////
  const gaugeProxyV1ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const iceQueenAddr = "0xB12531a2d758c7a8BF09f44FC88E646E1BF9D375";
  const userAddr = "0xdbc195a0ED72c0B059f8906e97a90636d2B6409F";
  const snobAddr = "0xC38f41A296A4493Ff429F1238e030924A1542e50";
  const gaugeProxyV1addr = "0xFc371bA1E7874Ad893408D7B581F3c8471F03D2C";
  ////////////////////////////////////////////////////////////////////////

  // INITIALIZE //////////////////////////////////////////////////////////
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

  // GAUGEPROXY V1 //////////////////////////////////////////////////////////
  console.log('-- Connect to GaugeProxyV1 --');
  const gaugeProxyV1 = new ethers.Contract(gaugeProxyV1addr, gaugeProxyV1ABI, governanceSigner);

  // GAUGEPROXY V2 //////////////////////////////////////////////////////////
  console.log("-- Deploying GaugeProxyV2 contract --");
  const GaugeProxyV2 = await hre.ethers.getContractFactory("GaugeProxyV2");
  const gaugeProxyV2 = await GaugeProxyV2.deploy();
  await gaugeProxyV2.deployed();

  const mSNOWCONESAddr = await gaugeProxyV2.TOKEN();
  console.log(`GaugeProxy deployed at ${gaugeProxyV2.address}`);

  console.log("-- Adding mSNOWCONES to iceQueen --");
  let populatedTx;
  populatedTx = await iceQueen.populateTransaction.add(
    5000000,
    mSNOWCONESAddr,
    false,
    { gasLimit: 9000000 }
  );
  await governanceSigner.sendTransaction(populatedTx);

  // GAUGEPROXY V3 ///////////////////////////////////////////////////////
  console.log("-- Deploying GaugeProxyV3 contract --");
  const gaugeProxyV3 = await GaugeProxyV2.deploy();
  await gaugeProxyV3.deployed();
  ////////////////////////////////////////////////////////////////////////



  // 1-2 HARD MIGRATION //////////////////////////////////////////////////
  let tokens = await gaugeProxyV1.tokens();
  let weights = [];
  console.log("-- Adding Tokens --");
  for (let i = 0; i < tokens.length; i++) {
    console.log(`-- token: ${tokens[i]} --`);
    await gaugeProxyV2.addGauge(tokens[i]);
    weights[i] = Math.floor(10000000 / tokens.length);
  }
  ////////////////////////////////////////////////////////////////////////
  
  console.log("-- impersonating User --");
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [userAddr],
  });

  const gaugeProxyV2FromUser = gaugeProxyV2.connect(userAddr);
  console.log("-- Voting on gauges --");

  populatedTx = await gaugeProxyV2FromUser.populateTransaction.vote(
    tokens,
    weights,
    {
      gasLimit: 9000000,
    }
  );

  await userSigner.sendTransaction(populatedTx);
  const pid = (await iceQueen.poolLength()) - 1;
  await gaugeProxyV2.setPID(pid);
  await gaugeProxyV2.deposit();

  console.log("-- Wait for 10 blocks to be mined --");
  for (let i = 0; i < 10; i++) {
    await hre.network.provider.request({
      method: "evm_mine",
    });
  }

  // DEPRECATE GAUGES ////////////////////////////////////////////////////
  console.log('-- Deprecating every 10th gauge --');
  for (let i = 0; i*10 < tokens.length; i++) {
    await gaugeProxyV2.deprecateGauge(tokens[i*10]);
  }

  console.log("-- Pre Distribute SNOB to gauges --");
  await gaugeProxyV2.preDistribute();

  console.log("-- Distribute SNOB to gauges --");
  let chunk = tokens.length > 50 ? 50 : tokens.length - 1;
  console.log(`-- chunking up ${tokens.length} gauges --`);
  for (let i = 0; i < tokens.length - chunk; i+= chunk) {
    console.log(`-- distribution for chunk ${i} to ${i+chunk} --`);
    await gaugeProxyV2.distribute(i,i+chunk);
    if (i+chunk+chunk > tokens.length) {
      chunk = tokens.length - i+chunk;
    }
  }

  const snob = await ethers.getContractAt("Snowball", snobAddr);

  for (const token of tokens) {
    let gauge = await gaugeProxyV2.getGauge(token);
    let reward = await snob.balanceOf(gauge);
    console.log(`rewards to ${token} gauge: ${reward}`);
  }


  /**  
   * We need to test...
   * 
   * GaugeProxy Migration:
   * Changing Governance for each Gauge
   * Changing the GaugeProxy for a Gauge
   * Migrate the Gauge to the new GaugeProxy
   * Foreign actor can't call these functions
   * 
   * Gauge Deprecation:
   * Mark a Gauge as Deprecated
   * Ensure that it isn't included in Distribution
   * Un Deprecate it
   * Ensure that it is included in Distribution
   * 
   * 
  */
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });