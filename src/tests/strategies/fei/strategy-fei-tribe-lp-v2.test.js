const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");

describe("StrategyFeiTribeLpV2", () => {
  const want_addr = "0x9928e4046d7c6513326cCeA028cD3e7a91c7590A";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(UNI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategyFeiTribeLpV2", want_addr, true);
});
