const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");


describe("StrategyLooksEthLp", () => {
  const want_addr = "0xDC00bA87Cc2D99468f7f34BC04CBf72E111A32f7";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(UNI_ROUTER, want_addr, toWei(10), alice);
  });

  doTestBehaviorBase("StrategyLooksEthLp", want_addr, true);
});
