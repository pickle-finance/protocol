const {toWei} = require("../../../../utils/testHelper");
const {getWantFromWhale} = require("../../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../../testBehaviorBase");

describe("StrategyLqdrPillsWftm", () => {
  const want_addr = "0x9C775D3D66167685B2A3F4567B548567D2875350";
  const whale_addr = "0xCeB46D7E286eBe800aC20bd716AA66D84010A52C";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqdrPillsWftm", want_addr, true);
});