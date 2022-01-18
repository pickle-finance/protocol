const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyAurumMaticLp", () => {
  const want_addr = "0x91670a2A69554c61d814CD7f406D7793387E68Ef";
  const whale_addr = "0xa531040422f158b6608c21d0b16ab3fdc095693b"

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(12000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyAurumMaticLp", want_addr);
});
 