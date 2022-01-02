import { doFoldingStrategyTest } from "./folding-strategy-test";
import type { FoldingStratTestCase } from "./FoldingStratTestCase";

// Leaving Strategy Address blank will make folding-strategy-test.js instead build and deploy a new Contract specified by stratABI
const globeABI = require('./abis/GlobeABI.json'); 
const stratBaseABI = require('./abis/StratBaseABI.json');

const tests: Array<FoldingStratTestCase> = [ 
  {
    name: "BenqiDai",
    tokenAddress: "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
    snowglobeAddress: "0x7b2525A502800E496D2e656e5b1188723e547012",
    strategyAddress: "",
    amount: "250000000000000000000000000",
    slot: 0,
    fold: true,
    controller: "main",
  },
  {
    name: "BenqiUsdc",
    tokenAddress: "0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",
    strategyAddress: "",
    snowglobeAddress: "0xa8981Eab82d0a471b37F7d87A221C92aE60c0E00",
    amount: "250000000000000000000000000",
    slot: 0,
    fold: true,
    controller: "main",
  },
  {
    name: "BenqiLink",
    tokenAddress: "0x5947bb275c521040051d82396192181b413227a3",
    strategyAddress: "",
    snowglobeAddress: "0x32d9D114A2F5aC4ce777463e661BFA28C8fE9Eb7",
    amount: "250000000000000000000000000",
    slot: 0,
    fold: true,
    controller: "main",
  },
  {
    name: "BenqiQi",
    tokenAddress: "0x8729438eb15e2c8b576fcc6aecda6a148776c0f5",
    strategyAddress: "",
    snowglobeAddress: "0x68b8037876385BBd6bBe80bAbB2511b95DA372C4",
    amount: "250000000000000000000000000",
    slot: 1,
    fold: false,
    controller: "backup",
  },
  {
    name: "BenqiWbtc",
    tokenAddress: "0x50b7545627a5162F82A992c33b87aDc75187B218",
    strategyAddress: "",
    snowglobeAddress: "0x8FA104f65BDfddEcA211867b77e83949Fc9d8b44",
    amount: "250000000000000000000000000",
    slot: 0,
    fold: true,
    controller: "main",
  },
  {
    name: "BenqiEth",
    tokenAddress: "0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB",
    strategyAddress: "",
    snowglobeAddress: "0x37d4b7B04ccfC14d3D660EDca1637417f5cA37f3",
    amount: "250000000000000000000000000",
    slot: 0,
    fold: true,
    controller: "main",
  },
  {
    name: "BenqiAvax",
    tokenAddress: "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
    strategyAddress: "",
    snowglobeAddress: "0x37d4b7B04ccfC14d3D660EDca1637417f5cA37f3",
    amount: "250000000000000000000000000",
    slot: 0,
    fold: true,
    controller: "main",
  },
];

describe("Benqi Folding Strategy", function () {
for (const test of tests) {
    doFoldingStrategyTest(
      test.name,
      test.tokenAddress,
      test.snowglobeAddress,
      test.strategyAddress,
      globeABI,
      stratBaseABI,
      test.amount,
      test.slot,
      test.fold,
      test.controller
      );
   }
});
