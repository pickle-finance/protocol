import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyEthBtcUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-eth-btc-lp.sol:StrategyEthBtcUniV3Optimism";
  const oldStrategy = "0x754ece9AC6b3FF9aCc311261EC82Bd1B69b8E00B";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});