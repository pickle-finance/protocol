import { toWei } from "../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "./strategyUniv3Base";

describe("StrategyEthLinkUniV3", () => {
  let strategyName = "StrategyEthLinkUniV3";
  const token0: TokenParams = {
    name: "LINK",
    tokenAddr: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
    whaleAddr: "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2",
    amount: toWei(100, 18),
  };
  const token1: TokenParams = {
    name: "WETH",
    tokenAddr: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    whaleAddr: "0x57757E3D981446D585Af0D9Ae4d7DF6D64647806",
    amount: toWei(10, 18),
  };
  let poolAddr = "0xa6Cc3C2531FdaA6Ae1A3CA84c2855806728693e8";
  let chain = "mainnet";

  doUniV3TestBehaviorBase(strategyName, token0, token1, poolAddr, chain);
});
