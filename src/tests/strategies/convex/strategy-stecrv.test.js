const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyConvexSteCRV", () => {
  const want_addr = "0x06325440D014e39736583c165C2963BA99fAf14E";
  const whale_addr = "0x56c915758ad3f76fd287fff7563ee313142fb663";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyConvexSteCRV", want_addr);
});
