const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyLqdrSushiWftm", () => {
  const want_addr = "0xf84E313B36E86315af7a06ff26C8b20e9EB443C3";
  const whale_addr = "0xb7d49ADB031d6DBDF3E8e28F21C6Dd3b6f231cD5";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqdrSushiWftm", want_addr, true);
});