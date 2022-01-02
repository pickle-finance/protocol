import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";

const tests = [
    {
        name: "JoeAvaxEgg",
        controller: "backup",
        lp_suffix: false,
        timelockIsStrategist: true,
        slot: 1, // error due to wrong slot -- _i think_ 
    },
];


describe("TraderJoe LP test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...LPTestDefault, ...test };
        doStrategyTest(Test);
    }
});
