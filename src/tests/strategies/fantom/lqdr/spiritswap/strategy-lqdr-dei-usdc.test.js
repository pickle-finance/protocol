const {toWei} = require("../../../../utils/testHelper");
const {getWantFromWhale} = require("../../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../../testBehaviorBase");

describe("StrategyLqdrDeiUsdc", () => {
  const want_addr = "0x8eFD36aA4Afa9F4E157bec759F1744A7FeBaEA0e";
  const whale_addr = "0xcbE9B07780B5f8C7F402ed8ae801831025496FeD";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, 6000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqdrDeiUsdc", want_addr, true);
});