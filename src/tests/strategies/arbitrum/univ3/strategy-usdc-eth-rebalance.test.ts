import { toWei } from "../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../../testUniv3Base";

describe("StrategyUsdcEthUniV3Arbi", () => {
  let strategyName = "StrategyUsdcEthUniV3Arbi";
  const token0: TokenParams = {
    name: "WETH",
    tokenAddr: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    whaleAddr: "0x4F76fF660dc5e37b098De28E6ec32978E4b5bEb6",
    amount: toWei(50, 18),
  };
  const token1: TokenParams = {
    name: "USDC",
    tokenAddr: "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
    whaleAddr: "0x1714400FF23dB4aF24F9fd64e7039e6597f18C2b",
    amount: toWei(60_000, 6),
  };
  let poolAddr = "0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443";
  let chain = "arbitrum";

  doUniV3TestBehaviorBase(strategyName, token0, token1, poolAddr, chain);
});
