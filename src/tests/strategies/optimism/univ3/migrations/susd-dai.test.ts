import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategySusdDaiUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-susd-dai-lp.sol:StrategySusdDaiUniV3Optimism";
  const oldStrategy = "0x1Bb40496D3074A2345d5e3Ac28b990854A7BDe34";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});