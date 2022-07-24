const { toWei } = require("../../utils/testHelper");
const { getWantFromWhale } = require("../../utils/setupHelper");
const { doTestBehaviorBase } = require("../testBehaviorBase");

describe("StrategyXdaiCurve3CRV", () => {
  const want_addr = "0x1337BedC9D22ecbe766dF105c9623922A27963EC";
  const whale_addr = "0xCED608Aa29bB92185D9b6340Adcbfa263DAe075b";
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(50), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyXdaiCurve3CRV", want_addr);
});
