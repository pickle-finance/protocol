import "@nomicfoundation/hardhat-toolbox";
import { doTestBehaviorBase } from "../../sushiswap/strategySushiBase";

const contract = "src/strategies/fantom/sushiswap/strategy-sushi-fusdt-ftm-slp.sol:StrategyFantomSushiFusdtFtmSlp";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
