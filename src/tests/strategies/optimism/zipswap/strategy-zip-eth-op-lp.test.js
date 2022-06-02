const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyZipEthOpLp", () => {
  const want_addr = "0x167dc49c498729223D1565dF3207771B4Ee19853";
  const whale_addr = "0xD0345e063FC2a9D45D9e7DcC8C2c448d411e843B";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyZipEthOpLp", want_addr, true);
});