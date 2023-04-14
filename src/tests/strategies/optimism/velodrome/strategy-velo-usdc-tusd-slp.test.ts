import "@nomicfoundation/hardhat-toolbox";
import { doTestBehaviorBase } from "./strategyVeloBase";

const contract = "src/strategies/optimism/velodrome/strategy-velo-usdc-tusd-slp.sol:StrategyVeloUsdcTusdSlp";
const name = contract.substring(contract.lastIndexOf(":") + 2);

describe(name, () => doTestBehaviorBase(contract, 6));
