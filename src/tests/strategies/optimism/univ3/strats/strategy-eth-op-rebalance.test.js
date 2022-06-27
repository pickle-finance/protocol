const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyEthOpUniV3Optimism", () => {
  let strategyName = "StrategyEthOpUniV3Optimism";
  let poolAddr = "0x68F5C0A2DE713a54991E01858Fd27a3832401849";
  let token0Name = "WETH";
  let token1Name = "OP";
  let token0Address = "0x4200000000000000000000000000000000000006";
  let token1Address = "0x4200000000000000000000000000000000000042";
  let token0Whale = "0x817B4eab0e595801f382f531E36245EbcD401452";
  let token1Whale = "0xEbe80f029b1c02862B9E8a70a7e5317C06F62Cae";
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
