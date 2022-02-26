const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyEthLooksUniV3", () => {
  let strategyName = "StrategyEthLooksUniV3";
  let poolAddr = "0x4b5Ab61593A2401B1075b90c04cBCDD3F87CE011";
  let token1Name = "LOOKS";
  let token0Name = "ETH";
  let token1Address = "0xf4d2888d29D722226FafA5d9B24F9164c092421E";
  let token0Address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  let token1Whale = "0x1Fc444e3E4C60e864BfBaA25953B42Fa73695Cf8";
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
