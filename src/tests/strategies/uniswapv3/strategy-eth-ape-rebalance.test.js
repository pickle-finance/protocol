const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyEthApeUniV3", () => {
  let strategyName = "StrategyEthApeUniV3";
  let poolAddr = "0xAc4b3DacB91461209Ae9d41EC517c2B9Cb1B7DAF";
  let token1Name = "ETH";
  let token0Name = "APE";
  let token1Address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  let token0Address = "0x4d224452801ACEd8B2F0aebE155379bb5D594381";
  let token1Whale = "0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3";
  let token0Whale = "0xA56CF001966d179751ba1c7FB5D137B4C5F344Cc";
  let isPolygon = false;
  let depositNative = false;
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
