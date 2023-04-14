import "@nomicfoundation/hardhat-toolbox";
import { doTestBehaviorBase } from "./strategyVeloBase";

const contract = "src/strategies/optimism/velodrome/strategy-velo-usdc-mai-slp.sol:StrategyVeloUsdcMaiSlp";
const name = contract.substring(contract.lastIndexOf(":") + 2);

describe(name, () => doTestBehaviorBase(contract, 6));
