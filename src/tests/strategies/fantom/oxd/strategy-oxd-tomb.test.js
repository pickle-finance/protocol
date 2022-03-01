const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdTomb", () => {
  const want_addr = "0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7";
  const whale_addr = "0x02517411f32ac2481753ad3045ca19d58e448a01";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdTomb", want_addr, true);
});