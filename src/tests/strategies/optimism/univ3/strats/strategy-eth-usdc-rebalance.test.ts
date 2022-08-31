import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategyEthUsdcUniV3Optimism", () => {
  let strategyName = "StrategyEthUsdcUniV3Optimism";
  const token0: TokenParams = {
    name: "WETH",
    tokenAddr: "0x4200000000000000000000000000000000000006",
    whaleAddr: "0x5a8D801d8B3a08B15C6D935B1a88ef0f2D2F860A",
    amount: toWei(50, 18)
  };
  const token1: TokenParams = {
    name: "USDC",
    tokenAddr: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
    whaleAddr: "0x6C788373151Af0A8eE43D15c6bA2c787f38472Ae",
    amount: toWei(100_000, 6)
  };
  let poolAddr = "0x85149247691df622eaF1a8Bd0CaFd40BC45154a9";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
