const hre = require("hardhat");
const {ethers} = require("hardhat");

const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";

async function advanceNDays(days) {
  /**************** increase time by 7 days ******************* */
  console.log(`-- Advancing ${days} dyas --`);
  await hre.network.provider.request({
    method: "evm_increaseTime",
    params: [3600 * 24 * days],
  });

  /** ******************* mine block ************************* */
  await hre.network.provider.request({
    method: "evm_mine",
  });
}

async function advanceSevenDays() {
  advanceNDays(7);
}

/**
 *
 * @param {contract} GaugeProxyV2
 * @param {array} lpAddr
 * @param {number} start
 * @param {number} end
 * @returns array
 */
async function distribute(GaugeProxyV2, lpAddr, start, end) {
  // await advanceSevenDays();
  console.log("This distribution is as per user's vote");
  console.log("Current Id => ", Number(await GaugeProxyV2.getCurrentPeriodId()));
  console.log("Distribution Id => ", Number(await GaugeProxyV2.distributionId()));
  await GaugeProxyV2.distribute(start, end);

  const pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);
  let rewards = [];

  lpAddr.forEach(async (lp) => {
    const gaugeAddr = await GaugeProxyV2.getGauge(lp);
    const rewardsGauge = await pickle.balanceOf(gaugeAddr);
    rewards.push(Number(rewardsGauge));
  });

  return rewards;
}

module.exports = {
  advanceNDays,
  advanceSevenDays,
  distribute,
};
