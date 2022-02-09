const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyDodoHndEthLpV3", () => {
  const want_addr = "0x65E17c52128396443d4A9A61EaCf0970F05F8a20";

  const whale_addr = "0x1001009911e3fe1d5b45ff8efea7732c33a6c012";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyDodoHndEthLpV3", want_addr, true, false);
});
