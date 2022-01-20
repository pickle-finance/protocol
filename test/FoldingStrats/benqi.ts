import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, FoldTestDefault } from "./../strategy-test-case";


const tests = [
    // {
    //   name: "BenqiUsdcE",
    //   controller: "main"
    // },
    {
      name: "BenqiLinkE",
      controller: "main",
      fold: false
    },
    // {
    //     name: "BenqiQi",
    //     fold: false,
    //     controller: "benqi",
    //     slot: 1
    // },
    // {
    //   name: "BenqiWbtcE",
    //   controller: "main",
    // },
    // {
    //   name: "BenqiEthE",
    //   controller: "main"
    // },
    // {
    //   name: "BenqiWavax",
    //   controller: "oldBenqi",
    //   timelockIsStrategist: true,
    //   slot: 3
    // },
    // {
    //     name: "BenqiDaiE",
    //     controller:"main"
    // },
    // {
    // name: "BenqiUsdtE", 
    // controller:"benqi",
    // },
];

describe("Benqi Folding Strategy Tests", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
