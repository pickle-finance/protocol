const hre = require("hardhat");

async function advanceSevenDays() {
  /** ************************************* increase time by 7 days ****************************************** */
  console.log("-- Wait 7 days to accumulate");
  await hre.network.provider.request({
    method: "evm_increaseTime",
    params: [3600 * 24 * 7],
  });

  /** ************************************* mine block ****************************************** */
  console.log("-- Wait for 1 block to be mined --");
  await hre.network.provider.request({
    method: "evm_mine",
  });
}

module.exports = {
  advanceSevenDays,
};
