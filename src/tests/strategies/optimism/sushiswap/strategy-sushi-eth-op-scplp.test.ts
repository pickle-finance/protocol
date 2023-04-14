import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/optimism/sushiswap/strategy-sushi-eth-op-scplp.sol:StrategyOpSushiEthOpScplp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6));
