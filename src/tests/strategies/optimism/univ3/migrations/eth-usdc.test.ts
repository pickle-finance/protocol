import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyEthUsdcUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyEthUsdcUniV3Optimism";
  const oldStrategy = "0x1570B5D17a0796112263F4E3FAeee53459B41A49";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});