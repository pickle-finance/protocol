import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/kava/sushiswap/strategy-sushi-kava-eth-scplp.sol:StrategyKavaSushiKavaEthScplp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
