const {toWei} = require("../../../utils/testHelper");
const {getERC20WithETH} = require("../../../utils/setupHelper");
const {doTestPusdBehaviorBase} = require("../../testPusdBehaviorBase");
const {UNI_ROUTER} = require("../../../utils/constants");

describe("StrategyPusdCrvUsdn", () => {
  const want_addr = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getERC20WithETH(UNI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestPusdBehaviorBase("StrategyPusdCrvUsdn", want_addr);
});
