import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/polygon/sushiswap/strategy-sushi-usdc-usdt-sslp.sol:StrategyPolySushiUsdcUsdtSslp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
