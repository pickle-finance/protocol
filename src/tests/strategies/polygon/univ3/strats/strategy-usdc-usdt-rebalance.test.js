const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyUsdcUsdtUniV3StakerPoly", () => {
  let strategyName = "StrategyUsdcUsdtUniV3StakerPoly";
  let poolAddr = "0x3F5228d0e7D75467366be7De2c31D0d098bA2C23";
  let token0Name = "USDC";
  let token1Name = "USDT";
  let token0Address = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  let token1Address = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";
  let token0Whale = "0xc25DC289Edce5227cf15d42539824509e826b54D";
  let token1Whale = "0x19f9dDA57196e161E8e943Bb0766C150F05FA3D5";
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
