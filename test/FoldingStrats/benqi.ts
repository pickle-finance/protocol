import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, FoldTestDefault } from "./../strategy-test-case";


const tests = [
    {
      name: "BenqiUsdcE",
      controller: "optimizer"
    },
    {
      name: "BenqiLinkE",
      controller: "optimizer"
    },
    // {
    //     name: "BenqiQi",
    //     fold: false,
    //     controller: "benqi",
    //     slot: 1
    // },
    {
      name: "BenqiWbtcE",
      controller: "optimizer",
    },
    {
      name: "BenqiEthE",
      controller: "optimizer"
    },
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
    {
      name: "BenqiUsdtE", 
      controller:"optimizer",
    },
    // {
    //     name: "BenqiWavax",
    //     slot: 3,
    //     controller:"optimizer"
    // },
    // {
    //     name: "BenqiDaiE",
    //     controller:"optimizer"
    // },
 
];

describe("Benqi Folding Strategy Tests", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
