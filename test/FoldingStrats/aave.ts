import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, FoldTestDefault } from "./../strategy-test-case";

const tests = [
    // {
    //     name: "AaveDai",
    //     strategyAddress: "0xfc26ec0c916b9f573bbdfd1eda87d5192339bd5b",
    //     snowglobeAddress: "0xE4543C234D4b0aD6d29317cFE5fEeCAF398f5649",
    //     amount: "250000000000000000000000",
    //     slot: 0,
    //     fold: true,
    //     controller: "aave",
    // },
    {
        name: "AaveUsdc",
        fold: true,
        controller: "optimizer",
    },
    {
        name: "AaveUsdt",
        fold: false,
        controller: "optimizer",
        slot: 0
    },
    {
        name: "AaveWbtc",
        slot: 0,
        fold: true,
        controller: "optimizer",
    },
    {
        name: "AaveWeth",
        slot: 0,
        fold: true,
        controller: "optimizer",
    },
    // {
    //     name: "AaveWavax",
    //     controller:"optimizer",
    //     slot: 3
    // },

];

describe("Aave Folding Strategies", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
