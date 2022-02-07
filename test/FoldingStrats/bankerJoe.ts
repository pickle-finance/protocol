import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, FoldTestDefault } from "./../strategy-test-case";


//Leaving Strategy Address blank will make generic-test.js instead build and deploy a new Contract specified by stratABI

const tests = [
    // {
    //     name: "JoeDai",
    //     tokenAddress: "0xd586E7F844cEa2F87f50152665BCbc2C279D8d70",
    //     strategyAddress: "0xcd9aa4d1a0cee1d0ed3798ded6fb925cbfe598a0",
    //     snowglobeAddress: "0x7b5FfCf45193986B757986379628432d90F20AAb",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeUsdc",
    //     tokenAddress: "0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",
    //     strategyAddress: "0xcd4a6733d1e497672290b0c4b891dfc10e03e973",
    //     snowglobeAddress: "0x8C9fAEBD41c68B801d628902EDad43D88e4dD0a6",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeUsdt",
    //     tokenAddress: "0xc7198437980c041c805A1EDcbA50c1Ce5db95118",
    //     strategyAddress: "0x3ef4dc17b344cd234fa264d8d0be424207f07532",
    //     snowglobeAddress: "0xc7Ca863275b2D0F7a07cA6e2550504362705aA1A",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeLink",
    //     tokenAddress: "0x5947bb275c521040051d82396192181b413227a3",
    //     strategyAddress: "0xce1a073f8df6796bd3b969f8ce1a04f569965a2b",
    //     snowglobeAddress: "0x6C6B562100663b4179C95E5B199576f2E16b150e",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeWbtc",
    //     tokenAddress: "0x50b7545627a5162F82A992c33b87aDc75187B218",
    //     strategyAddress: "0xa0a72f0b5056fba03158fc2d75cf6b4e364c6520",
    //     snowglobeAddress: "0xfb49ea67b84F7c1bBD825de7febd2C836BC4B47E",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeEth",
    //     tokenAddress: "0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB",
    //     strategyAddress: "0x09e26431e600f22d111a6f3c8f88d9bae2a64ad5",
    //     snowglobeAddress: "0x49e6A1255DEfE0B194a67199e78aD5AA5D7cb092",
    //     amount: "250000000000000000000000000",
    //     slot: 0,
    //     fold: false,
    //     controller: "bankerJoe",
    // },
    // {
    //     name: "JoeMim",
    //     slot: 2,
    //     fold: false,
    //     controller: "bankerJoe1",
    //     timelockIsStrategist: true,
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
    {
        name: "JoeAvax",
        controller: "bankerJoe1",
        strategyAddress: "",
        timelockIsStrategist: true,
        slot: 3,
        fold: false,
    }
];

describe("BankJoe Folding Strategy", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...FoldTestDefault, ...test };
        doStrategyTest(Test);
    }
});
