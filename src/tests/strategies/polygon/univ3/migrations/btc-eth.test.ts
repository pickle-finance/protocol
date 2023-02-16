import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyWbtcEthUniV3Poly Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/polygon/uniswapv3/strategy-univ3-wbtc-eth-lp.sol:StrategyWbtcEthUniV3Poly";
  const oldStrategy = "0xbE27C2415497f8ae5E6103044f460991E32636F8";
  const nativeAmountToDeposit = 100;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});
