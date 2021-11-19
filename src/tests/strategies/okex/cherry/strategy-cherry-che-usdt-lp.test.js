const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCherryCheUsdtLp", () => {
  const want_addr = "0x089dedbfd12f2ad990c55a2f1061b8ad986bff88";
  const whale_addr = "0xe6b8aa33b13bf5b9c11688360c0297331a75b903";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 16), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCherryCheUsdtLp", want_addr, true);
});