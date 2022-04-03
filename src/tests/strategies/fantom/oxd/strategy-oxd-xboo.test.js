const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdXboo", () => {
  const want_addr = "0xa48d959AE2E88f1dAA7D5F611E01908106dE7598";
  const whale_addr = "0x29d0e05ee48edc011993c3d91aefb1a5717ed46c";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdXboo", want_addr, true);
});