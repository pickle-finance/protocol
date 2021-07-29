const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyMim3Crv", () => {
  const want_addr = "0x5a6A4D54456819380173272A5E8E9B9904BdF41B";

  const whale_addr = "0x1889AF6eB9Bd12fA90FDB7A4C857Eff510d54530";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyMim3crvLp", want_addr);
});
