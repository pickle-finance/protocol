const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("./testBehaviorSwaprBase");

describe("StrategySwaprCowGnoLp", () => {
  const want_addr = "0xDBF14bce36F661B29F6c8318a1D8944650c73F38";
  const whale_addr = "0xF9f12F065499fAC55f031D11D1f1439e4BfA8525";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySwaprCowGnoLp", want_addr, native_token_addr);
});
