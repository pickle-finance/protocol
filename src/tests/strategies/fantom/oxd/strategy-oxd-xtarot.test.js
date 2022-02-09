const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdXtarot", () => {
  const want_addr = "0x74D1D2A851e339B8cB953716445Be7E8aBdf92F4";
  const whale_addr = "0x9429614ccabfb2b24f444f33ede29d4575ebcdd1";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdXtarot", want_addr, true);
});