const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const globes = [ 
    { name: "SnowGlobePngAvaxUsdtE", address: "0x7CC8068AB5FC2D8c843C4b1A6572a1d1E742D7c8" },
    { name: "SnowGlobePngAvaxDaiE", address: "0x56A6e103D860FBb991eF1Afd24250562a292b2a5" },
    { name: "SnowGlobePngAvaxSushiE", address: "0x5cce813cd2bBbA5aEe6fddfFAde1D3976150b860" },
    { name: "SnowGlobePngAvaxLinkE", address: "0x08D5Cfaf58a10D306937aAa8B0d2eb40466f7461" },
    { name: "SnowGlobePngAvaxWbtcE", address: "0x04A3B139fcD004b2A4f957135a3f387124982133" },
    { name: "SnowGlobePngAvaxEthE", address: "0xfEC005280ec0870A5dB1924588aE532743CEb90F" },
    { name: "SnowGlobePngAvaxYfiE", address: "0x2ad520b64e6058654FE6E67bc790221772b63ecE" },
    { name: "SnowGlobePngAvaxUniE", address: "0xf2596c84aCf1c7350dCF6941604DEd359dD506DB" },
    { name: "SnowGlobePngAvaxAaveE", address: "0x7F8E7a8Bd63A113B202AE905877918Fb9cA13091" },
    { name: "SnowGlobePngYfiEPng", address: "0xBc00e639a4795D7DfB43179866acB45eE5169fAE" },
    { name: "SnowGlobePngUniEPng", address: "0x351BA4c9b0F09aA76a8Aba8b1cF924aE98beb790" },
    { name: "SnowGlobePngAaveEPng", address: "0x9397A0257631955DBee5404506B363ab276D2315" },
    { name: "SnowGlobePngUsdtEPng", address: "0xb3DbF3ff266a604A66dbc1783257377239792828" },
    { name: "SnowGlobePngDaiEPng", address: "0x45981aB8cE749466c1d2022F50e24AbBEE71d15A" },
    { name: "SnowGlobePngSushiEPng", address: "0x384bcAEA70Ae79823312327a52e498E55c6730dA" },
    { name: "SnowGlobePngLinkEPng", address: "0x92f75Da67c5E647D86A56a5a3D6C9a25e887504A" },
    { name: "SnowGlobePngWbtcEPng", address: "0x857f9A61C97d175EaE9E0A8bb74CF701d45a18dc" },
    { name: "SnowGlobePngEthEPng", address: "0xEC7dA05C3FA5612f708378025fe1C0e1904aFbb5" },
  ];

  const [deployer] = await ethers.getSigners();

  const gaugeproxy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  const gaugeproxy_addr = "0xFc371bA1E7874Ad893408D7B581F3c8471F03D2C";

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