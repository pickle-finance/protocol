const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyConvexCvxCrv", () => {
  const want_addr = "0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7";
  const whale_addr = "0x00f282c40b92bed05f1776cadf1c8b96b9fbaee3";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyConvexCvxCrv", want_addr);
});
