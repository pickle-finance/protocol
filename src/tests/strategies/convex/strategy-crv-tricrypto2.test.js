const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyCrvTricrypto2", () => {
  const want_addr = "0xc4AD29ba4B3c580e6D59105FFf484999997675Ff";
  const whale_addr = "0x1ac7c010a7623f646d391c0c3e95135004702c8f";
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCrvTricrypto2", want_addr);
});
