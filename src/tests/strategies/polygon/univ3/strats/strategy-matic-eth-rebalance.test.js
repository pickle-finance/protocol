const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyMaticEthUniV3StakerPoly", () => {
  let strategyName = "StrategyMaticEthUniV3StakerPoly";
  let poolAddr = "0x167384319B41F7094e62f7506409Eb38079AbfF8";
  let token0Name = "MATIC";
  let token1Name = "ETH";
  let token0Address = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
  let token1Address = "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619";
  let token0Whale = "0xFAf6Ab3675EBA002C4955275A14154eFf5E27426";
  let token1Whale = "0x3EDC6fE5e041B9ED01e35CD644b395f6419A2f8a";
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
