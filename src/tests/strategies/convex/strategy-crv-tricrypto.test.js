const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");

describe("StrategyCrvTricrypto", () => {
  const want_addr = "0xcA3d75aC011BF5aD07a98d02f18225F9bD9A6BDF";
  const whale_addr = "0x9F719e0bc35c46236B3f450852B526d84FEd514b";
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(500), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCrvTricrypto", want_addr);
});
