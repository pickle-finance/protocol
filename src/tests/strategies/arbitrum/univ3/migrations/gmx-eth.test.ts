import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyGmxEthUniV3Arbi Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/arbitrum/uniswapv3/strategy-univ3-gmx-eth-lp.sol:StrategyGmxEthUniV3Arbi";
  const oldStrategy = "0x9C485ae43280dD0375C8c2290F1f77aee17CF512";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});