const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenUsdcDaiMaiLp", () => {
  const want_addr = "0x2C580C6F08044D6dfACA8976a66C8fAddDBD9901";
  const whale_addr = "0x3CC6Cc687870C972127E073E05b956A1eE270164";
  
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenUsdcDaiMaiLp", want_addr, true);
});
