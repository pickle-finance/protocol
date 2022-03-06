const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtmBifi", () => {
  const want_addr = "0xc28cf9aeBfe1A07A27B3A4d722C841310e504Fe3";
  const whale_addr = "0x4bDB54Ce2fD7c6f40e3Ab3A79e4DFCf739232398";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(2,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtmBifi", want_addr, true);
});