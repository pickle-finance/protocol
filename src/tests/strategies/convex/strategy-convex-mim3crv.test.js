const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyConvexMim3Crv", () => {
  const want_addr = "0x5a6A4D54456819380173272A5E8E9B9904BdF41B";
  const whale_addr = "0xdd8e2dd11d38b3e27ad4d7349a61b5c2b5af427a";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyConvexMim3Crv", want_addr);
});
