const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtmDeus", () => {
  const want_addr = "0x2599Eba5fD1e49F294C76D034557948034d6C96E";
  const whale_addr = "0x61DA1c9efF10334B371BAa36791Ef78Ad8349E23";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtmDeus", want_addr, true);
});