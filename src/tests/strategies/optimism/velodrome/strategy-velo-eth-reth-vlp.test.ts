import "@nomicfoundation/hardhat-toolbox";
import { doTestBehaviorBase } from "./strategyVeloBase";

const contract = "src/strategies/optimism/velodrome/strategy-velo-eth-reth-vlp.sol:StrategyVeloEthRethVlp";
const shortName = contract.substring(contract.lastIndexOf(":") + 2);

describe(shortName, () => doTestBehaviorBase(contract, 6));
