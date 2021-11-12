
/***
 *======== HOW TO USE THIS FILE ========
 * 
 *  ***/

const { doZapperTests } = require("../zapper-test");

const tests = [
    {
        name: "PngAvaxPng",
        snowglobeAddress: "0x621207093D2e65Bf3aC55dD8Bf0351B980A63815",
        gaugeAddress: "0xB99459c049aeE1AdB8b8E4E422bFDBc7081B2FAc",
        controller: "main"
    },
    // {
    //     name: "PngSnobPng",
    //     snowglobeAddress: "0xB4db531076494432eaAA4C6fCD59fcc876af2734",
    //     gaugeAddress: "0x2a83Cf1Cc8727D281C1afa9385d5E7f75B2FafB5",
    //     controller: "main"
    // },
    {
        name: "PngAavePng",
        snowglobeAddress: "0x9397A0257631955DBee5404506B363ab276D2315",
        gaugeAddress: "0xfd72D186ba9ac0f5f79f4370ba584B8Bda2ae4dd",
        controller: "main"
    },
    // {
    //     name: "PngAvaxShibx",
    //     snowglobeAddress: "0x4E9f0B7fa23e9197ca41AFB0E15C3175EDE57456",
    //     gaugeAddress: "0xdDe98d5057C6059A6935535404314808D7605b3d",
    //     controller: "main",
    // },
];


for (const test of tests) {
    describe(test.name, async () => {
        doZapperTests(test.name, test.snowglobeAddress, "Pangolin", test.gaugeAddress, test.controller);
    });
}
