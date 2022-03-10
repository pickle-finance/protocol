const { toWei } = require("../../utils/testHelper");
const { getWantFromWhale } = require("../../utils/setupHelper");
const { doTestBehaviorBase } = require("../testBehaviorBase");

describe("StrategyCurveStgUsdc", () => {
  const want_addr = "0xdf55670e27bE5cDE7228dD0A6849181891c9ebA1";
  const whale_addr = "0xfDC3D1f88805cCDc18340AB8A819d84e307BfAd2";
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(50), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCurveStgUsdc", want_addr);
});
