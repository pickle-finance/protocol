const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBxhUsdtLp", () => {
  const want_addr = "0x04b2C23Ca7e29B71fd17655eb9Bd79953fA79faF";
  const whale_addr = "0x56146b129017940d06d8e235c02285a3d05d6b7c";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(500), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBxhUsdtLp", want_addr, true);
});