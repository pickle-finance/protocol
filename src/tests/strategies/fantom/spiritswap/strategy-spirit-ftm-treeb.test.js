const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtmTreeb", () => {
  const want_addr = "0x2cEfF1982591c8B0a73b36D2A6C2A6964Da0E869";
  const whale_addr = "0x31fD0A6b0778aDEE3a12A8E3C2ABCEd6FFe6a92b";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtmTreeb", want_addr, true);
});