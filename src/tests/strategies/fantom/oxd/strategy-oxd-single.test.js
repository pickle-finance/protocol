const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdSingle", () => {
  const want_addr = "0xc165d941481e68696f43EE6E99BFB2B23E0E3114";
  const whale_addr = "0xe25bc2eb5be0f8605b47e79945a9cb11a0b2450f";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdSingle", want_addr, true);
});