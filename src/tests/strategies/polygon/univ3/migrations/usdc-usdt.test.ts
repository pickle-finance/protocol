import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyUsdcUsdtUniV3Poly Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/polygon/uniswapv3/strategy-univ3-usdc-usdt-lp.sol:StrategyUsdcUsdtUniV3Poly";
  const oldStrategy = "0x846d0ED75c285E6D70A925e37581D0bFf94c7651";
  const nativeAmountToDeposit = 100;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});
