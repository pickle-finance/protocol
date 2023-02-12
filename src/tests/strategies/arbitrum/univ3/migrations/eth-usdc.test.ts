import {doJarMigrationTest} from "../../../uniswapv3/jar-migration.test";

describe("StrategyUsdcEthUniV3Arbi Migration Test", () => {
  const newStrategyContractName =
    "src/strategies/arbitrum/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyUsdcEthUniV3Arbi";
  const oldStrategy = "0x41A610baad8BfdB620Badff488A034B06B13790D";
  const nativeAmountToDeposit = 0.1;

  doJarMigrationTest(newStrategyContractName, oldStrategy, nativeAmountToDeposit);
});