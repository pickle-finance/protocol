import "@nomicfoundation/hardhat-toolbox";
import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/arbitrum/sushiswap/strategy-sushi-rdpx-eth-slp.sol:StrategyArbSushiRdpxEthSlp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6));
