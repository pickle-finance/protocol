const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyEthBtcUniV3Optimism", () => {
  let strategyName = "StrategyEthBtcUniV3Optimism";
  let poolAddr = "0x73B14a78a0D396C521f954532d43fd5fFe385216";
  let token0Name = "WETH";
  let token1Name = "BTC";
  let token0Address = "0x4200000000000000000000000000000000000006";
  let token1Address = "0x68f180fcCe6836688e9084f035309E29Bf0A2095";
  let token0Whale = "0x817B4eab0e595801f382f531E36245EbcD401452";
  let token1Whale = "0x57bd982d577660Ab22d0a65d2C0a32E482112348";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0Name,
    token0Address,
    token1Name,
    token1Address,
    token0Whale,
    token1Whale,
    poolAddr,
    chain
  );
});
