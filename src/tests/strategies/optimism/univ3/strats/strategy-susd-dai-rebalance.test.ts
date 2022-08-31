import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategySusdDaiUniV3Optimism", () => {
  let strategyName = "StrategySusdDaiUniV3Optimism";
  const token0: TokenParams = {
    name: "SUSD",
    tokenAddr: "0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9",
    whaleAddr: "0xa5f7a39E55D7878bC5bd754eE5d6BD7a7662355b",
    amount: toWei(100_000, 18)
  };
  const token1: TokenParams = {
    name: "DAI",
    tokenAddr: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
    whaleAddr: "0xC86CB9c0A24CD123B67235c0e6bC60C72C5DC273",
    amount: toWei(100_000, 18)
  };
  let poolAddr = "0xAdb35413eC50E0Afe41039eaC8B930d313E94FA4";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
