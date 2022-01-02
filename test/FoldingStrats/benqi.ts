import { doFoldingStrategyTest } from "./../folding-strategy-test";


const tests = [
  // {
  //   name: "BenqiUsdcE",
  // },
  // {
  //   name: "BenqiLinkE",
  // },
  {
    name: "BenqiQi",
    fold: false,
    slot: 1
  },
  // {
  //   name: "BenqiWbtcE",
  // },
  // {
  //   name: "BenqiEthE",
  // },
  // {
  //   name: "BenqiWavax",
  // },
];

describe("Benqi Folding Strategy Tests", function () {
    for (const test of tests) {
        doFoldingStrategyTest(
            test.name,
            '',
            '',
            test.slot, // slot
            test.fold, // fold?
            "benqi"
        );
    }
});
