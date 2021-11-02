
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
    },
];

for (const test of tests) {
    describe(test.name, async () => {
        doZapperTests(test.name, test.snowglobeAddress, "Pangolin", test.gaugeAddress);
    });
}
