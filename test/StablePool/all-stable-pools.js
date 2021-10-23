/***
 *======== HOW TO USE THIS FILE ========
 * 1) Extend stable-pool-test.js with any addition functionality your pool adds
 * 2) Verify that the tokens in your pool are slot 0, if not add to helpers::findSlot()
 *      N.B   If you don't know how to find slot, consult README.md
 * 2) Add a new item below to the `tests` array, with the tokens in the pool and the
 *      deployed pool address (if any)
 * 3) Run this file e.g. `npx hardhat test test/StablePool/all-stable-pools.js`
 *      N.B. if you have deployed a stablepool via remix to hardhat you'll need to add -network localhost
 *      e.g. `npx hardhat test test/StablePool/all-stable-pools.js --network localhost`
 * 
 *  ***/
const { doStablePoolTests } = require("../stable-pool-test");

const tests = [
    {
        name: "s4D",
        addr: "0xA0bE4f05E37617138Ec212D4fB0cD2A8778a535F",
        tokens: [
            "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
            "0xdc42728b0ea910349ed3c6e1c9dc06b5fb591f98",
            "0x1c20e891bab6b1727d14da358fae2984ed9b59eb",
            "0xc7198437980c041c805a1edcba50c1ce5db95118"
        ]
    },
];

for (const test of tests) {
    describe(test.name, async () => {
        doStablePoolTests (
            test.name,
            test.addr,
            test.tokens)
    });
}
