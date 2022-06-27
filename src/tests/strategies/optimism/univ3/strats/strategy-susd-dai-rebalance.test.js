const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategySusdDaiUniV3Optimism", () => {
  let strategyName = "StrategySusdDaiUniV3Optimism";
  let poolAddr = "0xAdb35413eC50E0Afe41039eaC8B930d313E94FA4";
  let token0Name = "SUSD";
  let token1Name = "DAI";
  let token0Address = "0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9";
  let token1Address = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
  let token0Whale = "0xa5f7a39E55D7878bC5bd754eE5d6BD7a7662355b";
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
