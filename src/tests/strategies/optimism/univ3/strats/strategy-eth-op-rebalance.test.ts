import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategyEthOpUniV3Optimism", () => {
  let strategyName = "StrategyEthOpUniV3Optimism";
  const token0: TokenParams = {
    name: "WETH",
    tokenAddr: "0x4200000000000000000000000000000000000006",
    whaleAddr: "0x5a8D801d8B3a08B15C6D935B1a88ef0f2D2F860A",
    amount: toWei(50, 18)
  };
  const token1: TokenParams = {
    name: "OP",
    tokenAddr: "0x4200000000000000000000000000000000000042",
    whaleAddr: "0x790b4086D106Eafd913e71843AED987eFE291c92",
    amount: toWei(1_000_000, 18)
  };
  let poolAddr = "0x68F5C0A2DE713a54991E01858Fd27a3832401849";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
