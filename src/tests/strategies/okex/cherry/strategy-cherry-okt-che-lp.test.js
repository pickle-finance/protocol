const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCherryOktCheLp", () => {
  const want_addr = "0x8E68C0216562BCEA5523b27ec6B9B6e1cCcBbf88";
  const whale_addr = "0x8835a35023c2fcf105e1f232e600385ed6db9bc6";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 16), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCherryOktCheLp", want_addr, true);
});