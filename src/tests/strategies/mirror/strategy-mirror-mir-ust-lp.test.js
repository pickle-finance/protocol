const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");

describe("StrategyMirrorMirUstLp", () => {
  const want_addr = "0x87dA823B6fC8EB8575a235A824690fda94674c88";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(UNI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategyMirrorMirUstLp", want_addr);
});
