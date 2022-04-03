const {toWei} = require("../../../../utils/testHelper");
const {getWantFromWhale} = require("../../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../../testBehaviorBase");

describe("StrategyLqdrWftm", () => {
  const want_addr = "0x4Fe6f19031239F105F753D1DF8A0d24857D0cAA2";
  const whale_addr = "0xe6981106f75a97AE808A72733089070ce9A08CD5";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqdrWftm", want_addr, true);
});