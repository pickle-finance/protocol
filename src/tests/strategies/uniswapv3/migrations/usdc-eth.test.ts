import {doJarMigrationTest} from "../jar-migration.test";

describe("StrategyUsdcEth05UniV3 Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/uniswapv3/strategy-univ3-usdc-eth-05-lp.sol:StrategyUsdcEth05UniV3";
  const oldStrategy = "0xd33d3D71C6F710fb7A94469ED958123Ab86858b1";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});