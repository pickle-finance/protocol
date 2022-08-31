import { toWei } from "../../../../utils/testHelper";
import { doUniV3TestBehaviorBase, TokenParams } from "../strategyUniv3Base";


describe("StrategyEthBtcUniV3Optimism", () => {
  let strategyName = "StrategyEthBtcUniV3Optimism";
  const token0: TokenParams = {
    name: "WETH",
    tokenAddr: "0x4200000000000000000000000000000000000006",
    whaleAddr: "0x5a8D801d8B3a08B15C6D935B1a88ef0f2D2F860A",
    amount: toWei(50, 18)
  };
  const token1: TokenParams = {
    name: "BTC",
    tokenAddr: "0x68f180fcCe6836688e9084f035309E29Bf0A2095",
    whaleAddr: "0xfFA1b9Cc91663e098946De3055AeCdDFA4a33A6D",
    amount: toWei(10, 8)
  };
  let poolAddr = "0x73B14a78a0D396C521f954532d43fd5fFe385216";
  let chain = "optimism";

  doUniV3TestBehaviorBase(
    strategyName,
    token0,
    token1,
    poolAddr,
    chain
  );
});
