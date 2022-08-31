import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategyUsdcDaiUniV3Optimism", () => {
  let strategyName = "StrategyUsdcDaiUniV3Optimism";
  const token0: TokenParams = {
    name: "USDC",
    tokenAddr: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
    whaleAddr: "0x6C788373151Af0A8eE43D15c6bA2c787f38472Ae",
    amount: toWei(100_000, 6)
  };
  const token1: TokenParams = {
    name: "DAI",
    tokenAddr: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
    whaleAddr: "0xC86CB9c0A24CD123B67235c0e6bC60C72C5DC273",
    amount: toWei(100_000, 18)
  };
  let poolAddr = "0x100bdC1431A9b09C61c0EFC5776814285f8fB248";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
