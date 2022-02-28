const {toWei} = require("../../../../utils/testHelper");
const {getWantFromWhale} = require("../../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../../testBehaviorBase");

describe("StrategyLqdrSpiritWftm", () => {
  const want_addr = "0x30748322B6E34545DBe0788C421886AEB5297789";
  const whale_addr = "0x4Afe766592ac6095a3ba051f1f94607A0c49d9C2";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10000,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqdrSpiritWftm", want_addr, true);
});