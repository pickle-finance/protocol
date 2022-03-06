const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtmMai", () => {
  const want_addr = "0x51Eb93ECfEFFbB2f6fE6106c4491B5a0B944E8bd";
  const whale_addr = "0xa4c8d9e4ec5f2831701a81389465498b83f9457d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtmMai", want_addr, true);
});