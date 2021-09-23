const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {SUSHI_ROUTER} = require("../../utils/constants");


describe("StrategySushiTrueEthLp", () => {
  const want_addr = "0xfCEAAf9792139BF714a694f868A215493461446D";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(SUSHI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategySushiTrueEthLp", want_addr);
});
