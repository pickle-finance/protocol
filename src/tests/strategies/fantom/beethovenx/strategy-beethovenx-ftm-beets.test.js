const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenFtmBeetsLp", () => {
  const want_addr = "0xfcef8a994209d6916EB2C86cDD2AFD60Aa6F54b1";
  const whale_addr = "0x8661784b5d2d880f3DC80526A1cEF6E07011Fc1F";
  
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenFtmBeetsLp", want_addr, true);
});
