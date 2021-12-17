const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");

describe("StrategyRlyEthLp", () => {
  const want_addr = "0x27fD0857F0EF224097001E87e61026E39e1B04d1";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(UNI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategyRlyEthLp", want_addr);
});
