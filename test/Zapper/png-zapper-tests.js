
/***
 *======== HOW TO USE THIS FILE ========
 * 1) Extend single-stake-test.js with any addition functionality your single stake adds
 * 2) Verify that the tokens in your pool are slot 0, if not add to helpers::findSlot()
 *      N.B   If you don't know how to find slot, consult README.md
 * 3) Verify which controller your contracts are supposed to interact with
 * 4) Add a new item below to the `tests` array, with the tokens in the pool and the
 *      deployed contract addresses (if any)
 * 5) Run this file e.g. `npx hardhat test test/SingleStaking/all-singles.js`
 *      N.B. if you have deployed a stablepool via remix to hardhat you'll need to add -network localhost
 *      e.g. `npx hardhat test test/StablePool/all-stable-pools.js --network localhost`
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
