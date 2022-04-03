const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyRaiderWethLp", () => {
  const want_addr = "0x426a56f6923c2b8a488407fc1b38007317ecafb1";
  const whale_addr = "0xcdfdb12e854722b19dd59de0e8ff6d94246fb0f5"

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyRaiderWethLp", want_addr);
});
