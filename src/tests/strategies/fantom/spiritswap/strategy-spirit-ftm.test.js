const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtm", () => {
  const want_addr = "0x30748322B6E34545DBe0788C421886AEB5297789";
  const whale_addr = "0x6ec6E0F6892227BCb0754Fb71b37e57Aae1078Ef";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10000,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtm", want_addr, true);
});