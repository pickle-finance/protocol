const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");

describe("StrategyFoxEthFoxLp", () => {
  const want_addr = "0x470e8de2eBaef52014A47Cb5E6aF86884947F08c";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(UNI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategyFoxEthFoxLp", want_addr);
});
