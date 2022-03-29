import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";

const tests = [
    // {
    //     //users not earning
    //     name: "VtxUsdcE",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // },
    // {
    //     //users not earning
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
    //     //user not earning
    //     name: "VtxUsdtE",
    //     controller: "backup",
    //     timelockIsStrategist: true,
    //     slot: 0
    // }, 
    // {
    //     //user not earning
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
    {
        name: "VtxPtp",
        controller: "vector",
        slot: 4
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
