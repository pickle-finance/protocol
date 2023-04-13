import { doTestBehaviorBase } from "./strategySaddleBase";

const contract = "src/strategies/saddle/strategy-saddle-d4-v3.sol:StrategySaddleD4";
const name = contract.substring(contract.lastIndexOf(":") + 1);

describe(name, () => doTestBehaviorBase(contract, 6, 50));
