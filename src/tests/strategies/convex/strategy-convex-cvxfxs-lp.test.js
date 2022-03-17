const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyConvexCvxfxsLp", () => {
  const want_addr = "0xF3A43307DcAFa93275993862Aae628fCB50dC768";
  const whale_addr = "0x289c23Cd7cACAFD4bFee6344EF376FA14f1bF42D";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyConvexCvxfxsLp", want_addr);
});
