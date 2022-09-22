import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategyEthDaiUniV3Optimism", () => {
  let strategyName = "StrategyEthDaiUniV3Optimism";
  const token0: TokenParams = {
    name: "WETH",
    tokenAddr: "0x4200000000000000000000000000000000000006",
    whaleAddr: "0x5a8D801d8B3a08B15C6D935B1a88ef0f2D2F860A",
    amount: toWei(50, 18)
  };
  const token1: TokenParams = {
    name: "DAI",
    tokenAddr: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
    whaleAddr: "0xC86CB9c0A24CD123B67235c0e6bC60C72C5DC273",
    amount: toWei(100_000, 18)
  };
  let poolAddr = "0x03aF20bDAaFfB4cC0A521796a223f7D85e2aAc31";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
