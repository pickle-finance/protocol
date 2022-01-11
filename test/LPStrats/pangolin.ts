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
    {
        name: "PngAvaxQi",
        lp_suffix: false,
    },
    {
        name: "PngAvaxRoco",
        lp_suffix: false,
    },
    {
        name: "PngAvaxSnob",
        lp_suffix: false,
    },
    {
        name: "PngAvaxSpell",
        lp_suffix: false,
    },
    {
        name: "PngAvaxSpore",
        lp_suffix: false,
    },
    {
        name: "PngAvaxTeddy",
        lp_suffix: false,
    },
    {
        name: "PngAvaxTime",
        lp_suffix: false,
    },
    {
        name: "PngAvaxTusd",
        lp_suffix: false,
    },
    {
        name: "PngAvaxUsdcE",
    },
    {
        name: "PngAvaxUsdtE",
    },
    {
        name: "PngAvaxVee",
    },
    {
        name: "PngAvaxWalbt",
    },
    {
        name: "PngAvaxWbtcE",
    },
    {
        name: "PngAvaxWethE",
    },
    {
        name: "PngAvaxWow",
    },
    {
        name: "PngAvaxXava",
    },
    {
        name: "PngAvaxYak",
    },
    {
        name: "PngAvaxYay",
    },
    {
        name: "PngTusdDaiE",
    },
    {
        name: "PngUsdcEDaiE",
    },
    {
        name: "PngUsdcEMim",
    },
    {
        name: "PngUsdcEPng",
    },
    {
        name: "PngUsdcEUsdtE",
    },
    {
        name: "PngUsdtESkill",
    },
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
