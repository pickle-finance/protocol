const {doUniV3TestBehaviorBase} = require("./strategyUniv3Base");
describe("StrategyWbtcEthUniV3", () => {
  let strategyName = "StrategyWbtcEthUniV3";
  let poolAddr = "0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0";
  let token1Name = "ETH";
  let token0Name = "WBTC";
  let token1Address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  let token0Address = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
  let token1Whale = "0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3";
  let token0Whale = "0x6daB3bCbFb336b29d06B9C793AEF7eaA57888922";
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
