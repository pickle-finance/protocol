const hre = require("hardhat");
const {ethers} = require("hardhat");

// const pickleLP = "0xdc98556Ce24f007A5eF6dC1CE96322d65832A819";
const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
// const pyveCRVETH = "0x5eff6d166d66bacbc1bf52e2c54dd391ae6b1f48";

async function advanceSevenDays() {
  /** ************************************* increase time by 7 days ****************************************** */
  console.log("-- Advancing 7 dyas --");
  await hre.network.provider.request({
    method: "evm_increaseTime",
    params: [3600 * 24 * 7],
  });

  /** ************************************* mine block ****************************************** */
  await hre.network.provider.request({
    method: "evm_mine",
  });
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
  advanceSevenDays,
  distribute,
};
