import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";

const tests = [
    // {
    //     //user not earning
    //     name: "VtxUsdcE",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // },
    // {
    //     name: "VtxUsdc",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 9
    // },
    // {
    //     name: "VtxUsdt",
    //     controller: "vector",
    //     timelockIsStrategist: true,
    //     slot: 51
    // },
    // {
    //     name: "VtxUsdtE",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // }, 
    // {
    //     name: "VtxDaiE",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // },
    // {
    //     //harvest and user not earning tell jonas not to put on frontend
    //     name: "VtxAvaxVtx",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 1
    // },
    // {
    //     name: "VtxxPtpPtp",
    //     controller: "vector",
    //     timelockIsStrategist: true,
    //     slot: 1
    // },
    // {
    //     // ptp to xptp is not reversible
    //     name: "VtxPtp",
    //     controller: "vector",
    //     slot: 4
    // }, 
    {
        name: "VtxVtx",
        controller: "vector",
        slot: 0
    }, 
];

describe("Vector LP test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = {
            ...LPTestDefault,
            ...test,
            lp_suffix: false,
        };
        doStrategyTest(Test);
    }
});
