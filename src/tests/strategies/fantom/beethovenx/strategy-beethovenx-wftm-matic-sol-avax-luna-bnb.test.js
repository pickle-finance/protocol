const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenWftmMaticSolAvaxLunaBnbLp", () => {
  const want_addr = "0x9af1F0e9aC9C844A4a4439d446c1437807183075";
  const whale_addr = "0x959eEf9449dA238DA63962ce4aD2c9Efa7822276";
  
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenWftmMaticSolAvaxLunaBnbLp", want_addr, true);
});
