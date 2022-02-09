const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyRaiderMaticLp", () => {
  const want_addr = "0x2E7d6490526C7d7e2FDEa5c6Ec4b0d1b9F8b25B7";
  const whale_addr = "0xccdecf16bd1b552e029f57c203d3880b2c1ad630"

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(2000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyRaiderMaticLp", want_addr);
});
 