import {doJarMigrationTest} from "../jar-migration.test";

describe("StrategyEthCowUniV3 Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/uniswapv3/strategy-univ3-eth-cow-lp.sol:StrategyEthCowUniV3";
  const oldStrategy = "0x3B63E25e9fD76F152b4a2b6DfBfC402c5ba19A01";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});