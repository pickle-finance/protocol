const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdXcredit", () => {
  const want_addr = "0xd9e28749e80D867d5d14217416BFf0e668C10645";
  const whale_addr = "0x173492eeb441b96d288757b6fdc42a1a9440c831";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdXcredit", want_addr, true);
});