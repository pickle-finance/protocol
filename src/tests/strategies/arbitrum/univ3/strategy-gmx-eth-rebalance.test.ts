import { toWei } from "../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../../testUniv3Base";

describe("StrategyGmxEthUniV3Arbi", () => {
  let strategyName = "StrategyGmxEthUniV3Arbi";
  const token0: TokenParams = {
    name: "WETH",
    tokenAddr: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    whaleAddr: "0x4F76fF660dc5e37b098De28E6ec32978E4b5bEb6",
    amount: toWei(50, 18),
  };
  const token1: TokenParams = {
    name: "GMX",
    tokenAddr: "0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a",
    whaleAddr: "0xB38e8c17e38363aF6EbdCb3dAE12e0243582891D",
    amount: toWei(600, 18),
  };
  let poolAddr = "0x1aEEdD3727A6431b8F070C0aFaA81Cc74f273882";
  let chain = "arbitrum";

  doUniV3TestBehaviorBase(strategyName, token0, token1, poolAddr, chain);
});
