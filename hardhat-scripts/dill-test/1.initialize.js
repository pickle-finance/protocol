// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [governanceAddr],
  });

  const signer = ethers.provider.getSigner();
  console.log("-- Sending gas cost to governance addr --");
  await signer.sendTransaction({
    to: governanceAddr,
    value: ethers.BigNumber.from("1000000000000000000000"), // 1000 ETH
    data: undefined,
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
