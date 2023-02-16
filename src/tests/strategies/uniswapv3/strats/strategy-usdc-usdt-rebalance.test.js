const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyUsdcUsdtUniV3", () => {
  let strategyName = "StrategyUsdcUsdtUniV3";
  let poolAddr = "0x3416cF6C708Da44DB2624D63ea0AAef7113527C6";
  let token1Name = "USDT";
  let token0Name = "USDC";
  let token1Address = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  let token0Address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  let token1Whale = "0x61F2f664FEc20a2FC1D55409cFc85e1BaeB943e2";
  let token0Whale = "0xAe2D4617c862309A3d75A0fFB358c7a5009c673F";
  let isPolygon = false;
  let depositNative = false;
  let depositNativeTokenIs1 = false;
  let swapFee = 0;

  doUniV3TestBehaviorBase(
    strategyName,
    token0Name,
    token0Address,
    token1Name,
    token1Address,
    token0Whale,
    token1Whale,
    poolAddr,
    isPolygon,
    depositNative,
    depositNativeTokenIs1,
    swapFee
  );
});
