import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategySusdUsdcUniV3Optimism", () => {
  let strategyName = "StrategySusdUsdcUniV3Optimism";
  const token0: TokenParams = {
    name: "USDC",
    tokenAddr: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
    whaleAddr: "0x6C788373151Af0A8eE43D15c6bA2c787f38472Ae",
    amount: toWei(100_000, 6)
  };
  const token1: TokenParams = {
    name: "SUSD",
    tokenAddr: "0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9",
    whaleAddr: "0xa5f7a39E55D7878bC5bd754eE5d6BD7a7662355b",
    amount: toWei(100_000, 18)
  };
  let poolAddr = "0x8EdA97883a1Bc02Cf68C6B9fb996e06ED8fDb3e5";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
