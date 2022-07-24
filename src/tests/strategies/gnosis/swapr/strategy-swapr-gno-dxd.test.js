const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("./testBehaviorSwaprBase");

describe("StrategySwaprDxdGnoLp", () => {
  const want_addr = "0x558d777B24366f011E35A9f59114D1b45110d67B";
  const whale_addr = "0x33236B5B99d52E8366964c43F4211b959855eb0C";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, 0.002 * 10 ** 18, alice, whale_addr);
  });

  doTestBehaviorBase("StrategySwaprDxdGnoLp", want_addr, native_token_addr);
});
