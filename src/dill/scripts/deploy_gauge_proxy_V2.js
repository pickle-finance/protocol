const { ethers, upgrades } = require("hardhat");
/**
 * not working on mainnet fork, tested on mumbai 
 */
async function main() {
  console.log("Getting contract...");
  const gaugeProxyV2 = await ethers.getContractFactory(
    "contracts/gauge-proxy-v2.sol:GaugeProxyV2"
  );
  console.log("Deploying GaugeProxyV2...");
  const GaugeProxyV2 = await upgrades.deployProxy(gaugeProxyV2, {
    initializer: "initialize",
  });
  await GaugeProxyV2.deployed();
  console.log("GaugeProxyV2 deployed to:", GaugeProxyV2.address);
  // const GaugeProxyV2 = gaugeProxyV2.attach(
  //   "0xc6f33472A3d0E3450bd866Bf7286e5EF6dbD0157"
  // );
  // console.log(await GaugeProxyV2.test());
  // const pickle = await GaugeProxyV2.PICKLE();
  // console.log(pickle);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
