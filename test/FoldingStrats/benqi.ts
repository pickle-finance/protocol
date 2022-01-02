import { doStrategyTest } from "./../strategy-test";
import { IStrategyTestCase, FoldTestDefault } from "./../strategy-test-case";


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
];

describe("Benqi Folding Strategy Tests", function() {
    for (const test of tests) {
        let Test: IStrategyTestCase = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
