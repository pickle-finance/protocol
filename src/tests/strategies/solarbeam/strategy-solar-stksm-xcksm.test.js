const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyStksmXcksmLp", () => {
  const want_addr = "0x493147C85Fe43F7B056087a6023dF32980Bcb2D1";
  const whale_addr = "0x0ef8d50c2d7a737287755e2e9cec1a8cf403348a";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyStksmXcksmLp", want_addr, true);
});
