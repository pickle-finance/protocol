const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorSwaprBase");

describe("StrategySwaprGnoXdaiLp", () => {
  const want_addr = "0xD7b118271B1B7d26C9e044Fc927CA31DccB22a5a";
  const whale_addr = "0x9b04A9EeE500302980A117F514bc2DE0Fd1f683d";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase(
    "StrategySwaprGnoXdaiLp",
    want_addr,
    native_token_addr,
    true,
    true
  );
});

