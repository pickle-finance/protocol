const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyEthUsdcUniV3Optimism", () => {
  let strategyName = "StrategyEthUsdcUniV3Optimism";
  let poolAddr = "0x85149247691df622eaF1a8Bd0CaFd40BC45154a9";
  let token0Name = "WETH";
  let token1Name = "USDC";
  let token0Address = "0x4200000000000000000000000000000000000006";
  let token1Address = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";
  let token0Whale = "0x817B4eab0e595801f382f531E36245EbcD401452";
  let token1Whale = "0x1515C99A131fC770fB58090eb7398b6F383ad727";
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
