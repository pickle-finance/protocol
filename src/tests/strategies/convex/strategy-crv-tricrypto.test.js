const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyCrvTricrypto", () => {
  const want_addr = "0xcA3d75aC011BF5aD07a98d02f18225F9bD9A6BDF";
  const whale_addr = "0x8ACAFB4Eab93F19A54c9f96D929d3267947F9b7d";
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(50), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCrvTricrypto", want_addr);
});
