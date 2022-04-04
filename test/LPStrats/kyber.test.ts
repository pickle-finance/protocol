import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";


const tests = [
    // {
    //     name: "KySavaxAvax",
    //     controller: "kyber",
    //     slot: 0
    // },
    // {
    //     name: "KyKncQi",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // },
    // {
    //     name: "KySavaxKnc",
    //     controller: "kyber",
    //     slot: 0
    // },
    // {
    //     name: "KyUsdtEUsdt",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // },
    // {
    //     name: "KyUsdcEUsdc",
    //     controller: "backup",
    //     slot: 0
    // },
    {
        name: "KyAvaxWethE",
        controller: "kyber",
        slot: 0
    },
    {
        name: "KyAvaxKnc",
        controller: "kyber",
        slot: 0
    },
];

describe("Kyber Strategy test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...LPTestDefault, ...test };
        doStrategyTest(Test);
    }
});