const { ethers, upgrades } = require("hardhat");

async function main() {
  const GaugeProxyV2 = await ethers.getContractFactory("gaugeProxyV2");
  console.log("Upgrading GaugeProxy...");
  await upgrades.upgradeProxy(
    "",
    GaugeProxyV2
  );
  console.log("gaugeProxy upgraded");
}

main();
