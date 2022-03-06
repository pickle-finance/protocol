const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritScarabGscarab", () => {
  const want_addr = "0x8e38543d4c764DBd8f8b98C73407457a3D3b4999";
  const whale_addr = "0x2866Fbb4C8CF05b9601D051ea10f72de44b1E988";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritScarabGscarab", want_addr, true);
});