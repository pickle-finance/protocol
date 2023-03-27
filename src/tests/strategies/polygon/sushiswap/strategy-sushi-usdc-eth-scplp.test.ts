import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/polygon/sushiswap/strategy-sushi-usdc-eth-scplp.sol:StrategyPolySushiUsdcEthScplp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
