import "@nomicfoundation/hardhat-toolbox";
import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/fantom/sushiswap/strategy-sushi-yfi-eth-slp.sol:StrategyFantomSushiYfiEthSlp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
