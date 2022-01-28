const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyMaticUsdcUniV3StakerPoly", () => {
  let strategyName = "StrategyMaticUsdcUniV3StakerPoly";
  let poolAddr = "0x88f3C15523544835fF6c738DDb30995339AD57d6";
  let token0Name = "MATIC";
  let token1Name = "USDC";
  let token0Address = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
  let token1Address = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  let token0Whale = "0xFAf6Ab3675EBA002C4955275A14154eFf5E27426";
  let token1Whale = "0xc25DC289Edce5227cf15d42539824509e826b54D";
  let isPolygon = true;

  doUniV3TestBehaviorBase(
    strategyName,
    token0Name,
    token0Address,
    token1Name,
    token1Address,
    token0Whale,
    token1Whale,
    poolAddr,
    isPolygon
  );
});
