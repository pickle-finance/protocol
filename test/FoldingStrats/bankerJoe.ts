import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, FoldTestDefault } from "./../strategy-test-case";


//Leaving Strategy Address blank will make generic-test.js instead build and deploy a new Contract specified by stratABI

const tests = [
    // {
    //     name: "JoeDai",
    //     slot: 0,
    //     fold: true,
    //     controller: "optimizer",
    // },
    {
        name: "JoeUsdcE",
        slot: 0,
        fold: true,
        controller: "optimizer",
    },
    // {
    //     name: "JoeUsdtE",
    //     slot: 0,
    //     fold: true,
    //     controller: "optimizer",
    // },
    // {
    //     name: "JoeLinkE",
    //     slot: 0,
    //     fold: true,
    //     controller: "optimizer",
    // },
    {
        name: "JoeWbtcE",
        slot: 0,
        fold: true,
        controller: "optimizer",
    },
    {
        name: "JoeEthE",
        slot: 0,
        fold: true,
        controller: "optimizer",
    },
    {
        name: "JoeAvax",
        slot: 3,
        fold: true,
        controller: "optimizer",

    }
    // {
    //     name: "JoeMim",
    //     tokenAddress: "0x130966628846BFd36ff31a822705796e8cb8C18D",
    //     strategyAddress: "",
    //     snowglobeAddress: "",
    //     slot: 2,
    //     amount: "250000000000000000000000000",
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeXJoe",
    //     tokenAddress: "0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33",
    //     strategyAddress: "",
    //     snowglobeAddress: "0x6a52e6b23700A63eA4a0Db313eBD386Fb510eE3C",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // }
];

describe("BankJoe Folding Strategy", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
