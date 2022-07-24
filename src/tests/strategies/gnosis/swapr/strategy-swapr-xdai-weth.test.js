const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("./testBehaviorSwaprBase");

describe("StrategySwaprWethXdaiLp", () => {
  const want_addr = "0x1865d5445010E0baf8Be2eB410d3Eae4A68683c2";
  const whale_addr = "0x35E2acD3f46B13151BC941daa44785A38F3BD97A";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySwaprWethXdaiLp", want_addr, native_token_addr);
});
