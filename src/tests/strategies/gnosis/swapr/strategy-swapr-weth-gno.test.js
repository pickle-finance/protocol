const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorSwaprBase");

describe("StrategySwaprGnoWethLp", () => {
  const want_addr = "0x5fCA4cBdC182e40aeFBCb91AFBDE7AD8d3Dc18a8";
  const whale_addr = "0xa99640210D21A7318c3b85C19Ce5b3d49251E04d";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase(
    "StrategySwaprGnoWethLp",
    want_addr,
    native_token_addr,
    true,
    true
  );
});

