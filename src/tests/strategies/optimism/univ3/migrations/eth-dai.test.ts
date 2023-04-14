import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyEthDaiUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-eth-dai-lp.sol:StrategyEthDaiUniV3Optimism";
  const oldStrategy = "0xE9936818ecd2a6930407a11C090260b5390A954d";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});