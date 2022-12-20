const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("Getting contract...");
  const GaugeProxyV2 = await ethers.getContractFactory(
    "contracts/gauge-proxy-v2.sol:GaugeProxyV2"
  );
  console.log("Upgrading GaugeProxy...");
  const upgrade = await upgrades.upgradeProxy(
    "0xc6f33472A3d0E3450bd866Bf7286e5EF6dbD0157", // address of proxy deployed
    GaugeProxyV2
  );
  console.log("gaugeProxy upgraded");
  console.log(await upgrade.test());
  const pickle = await upgrade.PICKLE();
  console.log(pickle);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
