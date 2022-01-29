const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyDodoDodoUsdcLp", () => {
  const want_addr = "0x6a58c68FF5C4e4D90EB6561449CC74A64F818dA5";

  const whale_addr = "0x06f86834ee6821751b4c9a5fd534e32a49528a67";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyDodoDodoUsdcLp", want_addr);
});
