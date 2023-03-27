import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/kava/sushiswap/strategy-sushi-kava-usdc-scplp.sol:StrategyKavaSushiKavaUsdcScplp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
