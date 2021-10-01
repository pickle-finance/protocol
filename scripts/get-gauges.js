const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const globes = [ 
    { name: "SnowGlobeJoeUsdceEthe", address: "0x5586630339C015dF34EAB3Ae0343D37BE89671f9" },
    // { name: "SnowGlobeJoeAvaxBifi", address: "0xb58fA0e89b5a32E3bEeCf6B16704cabF8471F0E1" },
    // { name: "SnowGlobeJoeAvaxBnb", address: "0xc33b19c3d166CcD844aeDC475A989F5C0FC79E43" },
    // { name: "SnowGlobeJoeAvaxChart", address: "0x916aEbEE43E2bE7ed126A21208db4092392d80AD" },
    // { name: "SnowGlobeJoeAvaxKlo", address: "0xf6E8432EF7d85Ae1202Dc537106D3696eBB27769" },
    // { name: "SnowGlobeJoeAvaxMai", address: "0x29BF8c19e044732b110faA1Ff0Cc59CA35c13f17" },
    // { name: "SnowGlobeJoeAvaxMyak", address: "0xb81159B533F517f0E36978b7b8e9E8409fb9C169" },
    // { name: "SnowGlobeJoeAvaxRelay", address: "0x8C4185D7303c7865a45B46d705F40a8FAAd43Add" },
    // { name: "SnowGlobeJoeAvaxTeddy", address: "0xb357bA896818ccCd020fb3781a443E3d3f93beFf" },
    // { name: "SnowGlobeJoeAvaxTsd", address: "0xcEBFFa4C80291e80EA0684E4C8884124d6a81197" },
  ];

  const [deployer] = await ethers.getSigners();

  const gaugeproxy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  const gaugeproxy_addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";

  const fetchGauge = async globe => {
    const GaugeProxy = new ethers.Contract(gaugeproxy_addr, gaugeproxy_ABI, deployer);
    
    const gauge = await GaugeProxy.getGauge(globe.address);
    console.log(`${globe.name} has a gauge at ${gauge}`);
  };

  for (const globe of globes) {
    await fetchGauge(globe);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });