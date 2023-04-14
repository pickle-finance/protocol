import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyMaticUsdcUniV3Poly Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/polygon/uniswapv3/strategy-univ3-matic-usdc-lp.sol:StrategyMaticUsdcUniV3Poly";
  const oldStrategy = "0x293731CA8Da0cf1d6dfFB5125943F05Fe0B5fF99";
  const nativeAmountToDeposit = 100;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});
