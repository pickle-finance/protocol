import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategySusdUsdcUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-susd-usdc-lp.sol:StrategySusdUsdcUniV3Optimism";
  const oldStrategy = "0xa99e8a5754a53bE312Fba259c7C4619cfB00E849";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});