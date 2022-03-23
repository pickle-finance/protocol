const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("Getting contract...");
  const gaugeProxyV2 = await ethers.getContractFactory("contracts/gauge-proxy-v2.sol:GaugeProxyV2");
  console.log("Deploying GaugeProxyV2...");
  const GaugeProxyV2 = await upgrades.deployProxy(gaugeProxyV2);
  await GaugeProxyV2.deployed();
  console.log("GaugeProxyV2 deployed to:", GaugeProxyV2.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
