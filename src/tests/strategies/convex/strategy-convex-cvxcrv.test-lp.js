const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyConvexCvxCrvLp", () => {
  const want_addr = "0x9D0464996170c6B9e75eED71c68B99dDEDf279e8";
  const whale_addr = "0xfbd50c82ea05d0d8b6b302317880060bc3086866";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyConvexCvxCrvLp", want_addr);
});
