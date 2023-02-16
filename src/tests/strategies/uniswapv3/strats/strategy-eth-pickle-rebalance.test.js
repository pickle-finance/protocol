const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyEthPickleUniV3", () => {
  let strategyName = "StrategyEthPickleUniV3";
  let poolAddr = "0x11c4D3b9cd07807F455371d56B3899bBaE662788";
  let token0Name = "PICKLE";
  let token1Name = "ETH";
  let token0Address = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
  let token1Address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  let token0Whale = "0x2511132954b11fbc6bd56e6ec57161406ea31631";
  let token1Whale = "0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3";
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
