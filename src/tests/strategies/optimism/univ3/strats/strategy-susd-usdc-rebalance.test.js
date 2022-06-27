const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategySusdUsdcUniV3Optimism", () => {
  let strategyName = "StrategySusdUsdcUniV3Optimism";
  let poolAddr = "0x8EdA97883a1Bc02Cf68C6B9fb996e06ED8fDb3e5";
  let token0Name = "SUSD";
  let token1Name = "USDC";
  let token0Address = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";
  let token1Address = "0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9";
  let token0Whale = "0x1515C99A131fC770fB58090eb7398b6F383ad727";
  let token1Whale = "0xa5f7a39E55D7878bC5bd754eE5d6BD7a7662355b";
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
