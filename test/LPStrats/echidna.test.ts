import { doStrategyTest } from "../strategy-test";
import { TestableStrategy, LPTestDefault } from "../strategy-test-case";

const tests = [
    // {
    //     name: "EcdecdPTP",
    //     controller: "echidna",
    //     slot: 0
    // },
    // {   
    //     name: "EcdAvaxEcd",
    //     controller: "echidna",
    //     slot: 1
    // },
    // {
    //     name: "EcdPtpEcdPtp",
    //     controller: "echidna",
    //     slot: 1
    // },
    // {
    //     name: "EcdUsdtE",
    //     controller: "echidna",
    //     slot: 0
    // },
    {
        //user not earning
        name: "EcdUsdcE",
        controller: "echidna",
        slot: 0
    },
    // {
    //     name: "EcdDaiE",
    //     controller: "echidna",
    //     slot: 0
    // },
    {
        //users not earning
        name: "EcdUsdc",
        controller: "echidna",
        slot: 9
    },
    // {
    //     name: "EcdUsdt",
    //     controller: "echidna",
    //     slot: 51
    // },
];

describe("Echidna LP test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = {
            ...LPTestDefault,
            ...test,
            lp_suffix: false,
        };
        doStrategyTest(Test);
    }
});
