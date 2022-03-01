const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdUsdcLp", () => {
  const want_addr = "0xD5fa400a24EB2EA55BC5Bd29c989E70fbC626FfF";
  const whale_addr = "0xc8212a8f7a397f4e363fe5554fdd0f542e4fde3f";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3, 16), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdUsdcLp", want_addr, true);
});