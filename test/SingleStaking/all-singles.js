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

const { doSingleStakeTest } = require("../single-stake-test");
const tests = [
  //{
  // name: "JoexJoe",
  // tokenAddress: "0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33",
  // strategyAddress: "0x040D72568303927c8eEf626ec8AB8271162dA120",
  // snowglobeAddress: "0x8c06828A1707b0322baaa46e3B0f4D1D55f6c3E6",
  //},
  {
    name: "PngXPngLp",
    tokenAddress: "0x60781C2586D68229fde47564546784ab3fACA982",
    // strategyAddress: "0xA1EdFF60A604BB9dFEf25fc00b6D82a07cEAAf91",
    snowglobeAddress: "0xA22D8FD15FB36aA9e1Db795A78db8b688F6284F6",
    controller: "backup",
  },
  // {
  //   name: "TeddyxTeddy",
  //   tokenAddress: "0x094bd7B2D99711A1486FB94d4395801C6d0fdDcC",
  //   strategyAddress: "",
  //   snowglobeAddress: "",
  // },
];

for (const test of tests) {
  describe(test.name, async () => {
    doSingleStakeTest(
      test.name,
      test.tokenAddress,
      test.snowglobeAddress,
      test.strategyAddress,
      test.controller
    );
  });
}
