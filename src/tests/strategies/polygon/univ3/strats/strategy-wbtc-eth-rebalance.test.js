const {doUniV3TestBehaviorBase} = require("../strategyUniv3Base");
describe("StrategyWbtcEthUniV3StakerPoly", () => {
  let strategyName = "StrategyWbtcEthUniV3StakerPoly";
  let poolAddr = "0x50eaEDB835021E4A108B7290636d62E9765cc6d7";
  let token1Name = "ETH";
  let token0Name = "WBTC";
  let token1Address = "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619";
  let token0Address = "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6";
  let token1Whale = "0x3EDC6fE5e041B9ED01e35CD644b395f6419A2f8a";
  let token0Whale = "0x7c78A5C8A293f887bd968cDC3154FB0578E7bf19";
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
