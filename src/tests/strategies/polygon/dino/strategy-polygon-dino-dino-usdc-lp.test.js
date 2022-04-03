const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyDinoDinoUsdcLp", () => {
  const want_addr = "0x3324af8417844e70b81555A6D1568d78f4D4Bf1f";
  const whale_addr = "0x6eb42a61e3CCA07aD1F6f4494F4eD3428cb44Ea3";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 16), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyDinoDinoUsdcLp", want_addr, false, true);
});
