import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";

const tests = [
    //   {
    //     name: "PngAvaxAmpl",
    //   },
    //   {
    //     name: "PngAvaxApein",
    //   },
    //   {
    //     name: "PngAvaxAvai",
    //   },
    //   {
    //     name: "PngAvaxCly",
    //   },
    //   {
    //     name: "PngAvaxCook",
    //   },
    //   {
    //     name: "PngAvaxCra",
    //   },
    //   {
    //     name: "PngAvaxCraft",
    //   },
    //   {
    //     name: "PngAvaxDaiE",
    //   },
    //   {
    //     name: "PngAvaxDyp",
    //   },
    //   {
    //     name: "PngAvaxFrax",
    //   },
    //   {
    //     name: "PngAvaxgOhm",
    //   },
    //   {
    //     name: "PngAvaxHct",
    //   },
    //   {
    //     name: "PngAvaxHusky",
    //   },
    //   {
    //     name: "PngAvaxImxa",
    //   },
    //   {
    //     name: "PngAvaxInsur",
    //   },
    //   {
    //     name: "PngAvaxJewel",
    //   },
    //   {
    //     name: "PngAvaxJoe",
    //   },
    //   {
    //     name: "PngAvaxKlo",
    //   },
    //   {
    //     name: "PngAvaxLinkE",
    //   },
    //   {
    //     name: "PngAvaxMaxi",
    //   },
    //   {
    //     name: "PngAvaxMim",
    //   },
    //   {
    //     name: "PngAvaxOoe",
    //   },
    //   {
    //     name: "PngAvaxOrbs",
    //   },
    //   {
    //     name: "PngAvaxOrca",
    //   },
    //   {
    //     name: "PngAvaxPefi",
    //   },
    //   {
    //     name: "PngAvaxPng",
    //   },
    // {
    //     name: "PngAvaxQi",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxRoco",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxSnob",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxSpell",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxSpore",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxTeddy",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxTime",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxTusd",
    //     lp_suffix: false,
    // },
    // {
    //     name: "PngAvaxUsdcE",
    // },
    // {
    //     name: "PngAvaxUsdtE",
    // },
    // {
    //     name: "PngAvaxVee",
    // },
    // {
    //     name: "PngAvaxWalbt",
    // },
    // {
    //     name: "PngAvaxWbtcE",
    // },
    // {
    //     name: "PngAvaxWethE",
    // },
    // {
    //     name: "PngAvaxWow",
    // },
    // {
    //     name: "PngAvaxXava",
    // },
    // {
    //     name: "PngAvaxYak",
    // },
    // {
    //     name: "PngAvaxYay",
    // },
    // {
    //     name: "PngTusdDaiE",
    // },
    // {
    //     name: "PngUsdcEDaiE",
    // },
    // {
    //     name: "PngUsdcEMim",
    // },
    // {
    //     name: "PngUsdcEPng",
    // },
    // {
    //     name: "PngUsdcEUsdtE",
    // },
    // {
    //     name: "PngUsdtESkill",
    // },
    // {
    //     name: "PngAvaxLoot",
    //     controller: "main"
    // },
    // {
    //     name: "PngAvaxDcau",
    //     controller: "main"
    // },
    // {
    //     name: "PngAvaxMage",
    //     controller: "main"
    // },
    // {
    //     name: "PngAvaxPln",
    //     controller: "main"
    // },
    // {
    //     name: "PngAvaxHtz",
    //     controller: "main"
    // },
    // {
    //     name: "PngAvaxAgEUR",
    //     controller: "main",
    //     slot: 3
    // },
    // {
    //     name: "PngAvaxUst",
    //     controller: "main"
    // },
    {
        name: "PngAvaxLuna",
        controller: "main"
    },
    // {
    //     name: "PngUsdcUst",
    //     controller: "main",
    //     slot: 1
    // },
];

describe("Pangolin LP test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = {
            ...LPTestDefault,
            ...test,
            lp_suffix: false,
            slot: 1
        };
        doStrategyTest(Test);
    }
});
