import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, FoldTestDefault } from "./../strategy-test-case";


const tests = [
    // {
    //   name: "BenqiUsdcE",
    //   controller: "benqi",
    // },
    // {
    //   name: "BenqiLinkE",
    //   controller: "benqi",
    // },
    {
        name: "BenqiQi",
        fold: false,
        controller: "benqi",
        slot: 1
    },
    // {
    //   name: "BenqiWbtcE",
    //   controller: "benqi",
    // },
    // {
    //   name: "BenqiEthE",
    //   controller: "benqi",
    // },
    // {
    //   name: "BenqiWavax",
    //   controller: "benqi",
    // },
    {
        name: "BenqiWavax",
        slot: 1,
        controller:"optimizer"
    },
    {
        name: "BenqiDaiE",
        controller:"optimizer"
    },
 
];

describe("Benqi Folding Strategy Tests", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
