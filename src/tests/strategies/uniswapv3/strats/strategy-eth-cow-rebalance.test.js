const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyEthCowUniV3", () => {
  let strategyName = "StrategyEthCowUniV3";
  let poolAddr = "0xFCfDFC98062d13a11cec48c44E4613eB26a34293";
  let token1Name = "COW";
  let token0Name = "ETH";
  let token1Address = "0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB";
  let token0Address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  let token1Whale = "0x39D787fdf7384597C7208644dBb6FDa1CcA4eBdf";
  let token0Whale = "0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3";
  let isPolygon = false;
  let depositNative = true;
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
