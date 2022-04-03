const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBxhXusdtStaking", () => {
  const want_addr = "0x8E017294cB690744eE2021f9ba75Dd1683f496fb";
  const whale_addr = "0x1d0f84413d4cbc28fd5371cca5e7e7b9a91b9132";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(500), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBxhXusdtStaking", want_addr, true);
});