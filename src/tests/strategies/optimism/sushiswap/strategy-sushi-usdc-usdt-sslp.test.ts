import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/optimism/sushiswap/strategy-sushi-usdc-usdt-sslp.sol:StrategyOpSushiUsdcUsdtSslp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6));
