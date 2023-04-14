import {doJarMigrationTest} from "../jar-migration.test";

describe("StrategyApeEthUniV3 Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/uniswapv3/strategy-univ3-ape-eth-lp.sol:StrategyApeEthUniV3";
  const oldStrategy = "0x5e20293615A4Caa3E2a9B5D24B40DBB176Ec01a8";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});