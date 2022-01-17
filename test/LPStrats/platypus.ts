import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";


const tests = [
   
    {
        name: "PlatypusUsdtE",
        controller: "axial",
        timelockIsStrategist: false,
        slot: 0
    },
];

describe("Platypus Strategy test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...LPTestDefault, ...test };
        doStrategyTest(Test);
    }
});