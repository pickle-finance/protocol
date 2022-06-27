const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyUsdcDaiUniV3Optimism", () => {
  let strategyName = "StrategyUsdcDaiUniV3Optimism";
  let poolAddr = "0x100bdC1431A9b09C61c0EFC5776814285f8fB248";
  let token0Name = "USDC";
  let token1Name = "DAI";
  let token0Address = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";
  let token1Address = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
  let token0Whale = "0x1515C99A131fC770fB58090eb7398b6F383ad727";
  let token1Whale = "0xB97A258bB08F4c7E94Af9665BbCf4E8788038493";
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
