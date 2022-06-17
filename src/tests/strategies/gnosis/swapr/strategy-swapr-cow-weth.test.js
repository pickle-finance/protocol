const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorSwaprBase");

describe("StrategySwaprCowWethLp", () => {
  const want_addr = "0x8028457E452D7221dB69B1e0563AA600A059fab1";
  const whale_addr = "0x0066eA8811856575B8D442387b10b77B1916Ecf9";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase(
    "StrategySwaprCowWethLp",
    want_addr,
    native_token_addr,
    true,
    true
  );
});

