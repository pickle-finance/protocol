import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyUsdcEthUniV3Poly Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/polygon/uniswapv3/strategy-univ3-usdc-eth-lp.sol:StrategyUsdcEthUniV3Poly";
  const oldStrategy = "0xD5236f71580E951010E814118075F2Dda90254db";
  const nativeAmountToDeposit = 100;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});
