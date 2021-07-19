const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");

describe("StrategyUniLusdLp", () => {
  const want_addr = "0xF20EF17b889b437C151eB5bA15A47bFc62bfF469";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(UNI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategyLusdEthLp", want_addr);
});
