import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";

const tests = [
    // {
    //     name: "JoeAvaxEgg",
    //     controller: "bankerJoe",
    //     lp_suffix: false,
    //     timelockIsStrategist: true,
    //     slot: 1,
    // },
    // {
    //     name: "JoeUsdcEUsdc",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxPtp",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxPln",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxIme",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxH2O",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxCly",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeFraxgOhm",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxFrax",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxJgn",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxIsa",
    //     controller: "backup",
    //     lp_suffix: false,
    // },
    // {
    //     name: "JoeAvaxCook",
    //     controller: "traderJoe",
    //     slot: 1
    // },
    // {
    //     name: "JoeAvaxFxs",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    // {
    //     name: "JoeAvaxMore",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    // {
    //     name: "JoeAvaxUst",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    // {
    //     name: "JoeAvaxMore",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    // {
    //     name: "JoeAvaxDomi",
    //     controller: "traderJoe",
    //     slot: 1
    // },
    // {
    //     name: "JoeAvaxGmx",
    //     controller: "traderJoe",
    //     slot: 1
    // },
    // {
    //     name: "JoeAvaxHon",
    //     controller: "traderJoe",
    //     slot: 1
    // },
    // {
    //     name: "JoeAvaxTus",
    //     controller: "traderJoe",
    //     slot: 1
    // },
    // {
    //     name: "JoeAvaxUsdc",
    //     controller: "traderJoe",
    //     slot: 1
    // },
    // {
    //     name: "JoeUsdcEUst",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    // {
    //     name: "JoeAvaxSavax",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    {
        name: "JoeAvaxDfiat",
        controller: "traderJoe",
        slot: 1
    },
    // {
    //     name: "JoeAvaxFief",
    //     controller: "traderJoe",
    //     slot: 1
    // }
    {
        name: "JoeAvaxEcd",
        controller: "traderJoe",
        slot: 1
    },
    {
        name: "JoeAvaxMoney",
        controller: "traderJoe",
        slot: 1
    },
    {
        name: "JoeAvaxVtx",
        controller: "traderJoe",
        slot: 1
    }
];

describe("TraderJoe LP test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...LPTestDefault, ...test };
        doStrategyTest(Test);
    }
});