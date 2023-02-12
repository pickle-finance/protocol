import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyEthOpUniV3Optimism Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/optimism/uniswapv3/strategy-univ3-eth-op-lp.sol:StrategyEthOpUniV3Optimism";
  const oldStrategy = "0x1634e17813D54Ffc7506523D6e8bf08556207468";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});