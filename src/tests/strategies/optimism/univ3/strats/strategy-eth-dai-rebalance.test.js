const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyEthDaiUniV3Optimism", () => {
  let strategyName = "StrategyEthDaiUniV3Optimism";
  let poolAddr = "0x03aF20bDAaFfB4cC0A521796a223f7D85e2aAc31";
  let token0Name = "WETH";
  let token1Name = "DAI";
  let token0Address = "0x4200000000000000000000000000000000000006";
  let token1Address = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
  let token0Whale = "0x817B4eab0e595801f382f531E36245EbcD401452";
  let token1Whale = "0xB97A258bB08F4c7E94Af9665BbCf4E8788038493";
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
