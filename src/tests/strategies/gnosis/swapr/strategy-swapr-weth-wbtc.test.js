const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorSwaprBase");

describe("StrategySwaprWethWbtcLp", () => {
  const want_addr = "0xf6Be7AD58F4BAA454666b0027839a01BcD721Ac3";
  const whale_addr = "0xb4633912c7374cd94D8917a167449e23b46d0AD1";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, 5531516331, alice, whale_addr);
  });

  doTestBehaviorBase(
    "StrategySwaprWethWbtcLp",
    want_addr,
    native_token_addr,
    true,
    true
  );
});

