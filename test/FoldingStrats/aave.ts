import { doStrategyTest } from "./../strategy-test";
import { IStrategyTestCase, FoldTestDefault } from "./../strategy-test-case";

const tests = [
    {
        name: "AaveWavax",
        strategyAddress: "0xefb83d176c6632cf787214b7e130aaca99d936ff",
        snowglobeAddress: "0x951f6c751A9bC5A75a4E4d43be205aADa709D3B8",
        amount: "250000000000000000000000",
        slot: 3,
        fold: true,
        controller: "aave",
    },
    {
        name: "AaveDai",
        strategyAddress: "0xfc26ec0c916b9f573bbdfd1eda87d5192339bd5b",
        snowglobeAddress: "0xE4543C234D4b0aD6d29317cFE5fEeCAF398f5649",
        amount: "250000000000000000000000",
        slot: 0,
        fold: true,
        controller: "aave",
    },
    {
        name: "AaveUsdc",
        strategyAddress: "0xfce6dee4805df0c8bb981549e92922485c90861e",
        snowglobeAddress: "0x0c33d6076F0Dce93db6e6103E98Ad951A0F33917",
        amount: "250000000000000000000000",
        slot: 0,
        fold: true,
        controller: "aave",
    },
    {
        name: "AaveUsdt",
        strategyAddress: "0x1c670e7d2b294e24f71d61f7e0abf5d51fad69fe",
        snowglobeAddress: "0x567350328dB688d49284e79F7DBfad2AAd094B7A",
        amount: "250000000000000000000000",
        slot: 0,
        fold: true,
        controller: "aave",
    },
    {
        name: "AaveWbtc",
        strategyAddress: "0x569b2b8254b6887c6a9f310de220506c8e0e2256",
        snowglobeAddress: "0xcB707aA965aEB9cB03d21dFADf496e6581Cd7b96",
        amount: "250000000000000000000000",
        slot: 0,
        fold: true,
        controller: "aave",
    },
    {
        name: "AaveWeth",
        strategyAddress: "0x297991e25f6c4ecb3d10e9c6ee55767d6b727b8c",
        snowglobeAddress: "0x72b7AddaeFE3e4b6452CFAEcf7C0d11e5EBD05a0",
        amount: "250000000000000000000000",
        slot: 0,
        fold: true,
        controller: "aave",
    },
];

describe("Aave Folding Strategies", function() {
    for (const test of tests) {
        let Test: IStrategyTestCase = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
