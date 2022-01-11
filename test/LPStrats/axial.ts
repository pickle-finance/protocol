import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";


const tests = [
    {
        name: "AxialAM3D",
        controller: "axial",
        timelockIsStrategist: false,
        slot: 51
    },
];

describe("Axial Strategy test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...LPTestDefault, ...test };
        doStrategyTest(Test);
    }
});