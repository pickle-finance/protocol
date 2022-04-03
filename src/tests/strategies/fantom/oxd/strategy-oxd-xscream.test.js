const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdXscream", () => {
  const want_addr = "0xe3D17C7e840ec140a7A51ACA351a482231760824";
  const whale_addr = "0x343a6Aed149f6412500B6f6bedBe85f3DD23ba91";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdXscream", want_addr, true);
});