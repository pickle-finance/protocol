import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyMaticEthUniV3Poly Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/polygon/uniswapv3/strategy-univ3-matic-eth-lp.sol:StrategyMaticEthUniV3Poly";
  const oldStrategy = "0x11b8c80F452e54ae3AB2E8ce9eF9603B0a0f56D9";
  const nativeAmountToDeposit = 100;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});
