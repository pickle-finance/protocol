import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyUsdcDaiUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-usdc-dai-lp.sol:StrategyUsdcDaiUniV3Optimism";
  const oldStrategy = "0x387C985176A314c9e5D927a99724de98576812aF";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});