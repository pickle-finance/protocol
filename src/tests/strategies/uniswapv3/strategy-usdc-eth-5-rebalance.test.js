const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyUsdcEth05UniV3", () => {
  let strategyName = "StrategyUsdcEth05UniV3";
  let poolAddr = "0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640";
  let token1Name = "ETH";
  let token0Name = "USDC";
  let token1Address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  let token0Address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  let token1Whale = "0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3";
  let token0Whale = "0xAe2D4617c862309A3d75A0fFB358c7a5009c673F";
  let isPolygon = false;
  let depositNative = true;
  let depositNativeTokenIs1 = true;
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
