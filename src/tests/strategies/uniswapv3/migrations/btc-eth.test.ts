import {doJarMigrationTest} from "../jar-migration.test";

describe("StrategyWbtcEthUniV3 Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/uniswapv3/strategy-univ3-wbtc-eth-lp.sol:StrategyWbtcEthUniV3";
  const oldStrategy = "0xae2e6daA0FD5c098C8cE87Df573E32C9d6493384";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});