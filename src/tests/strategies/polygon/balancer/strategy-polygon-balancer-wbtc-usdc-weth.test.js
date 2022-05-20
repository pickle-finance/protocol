const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {doTestBalancerBehaviorBase} = require("./testBalancerBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyBalancerWbtcUsdcWethLp", () => {
  const want_addr = "0x03cD191F589d12b0582a99808cf19851E468E6B5";
  const whale_addr = "0x5a2d0e3D6f862EE155F52ab65b6b22e1D80f5716";
  const bal_addr = "0x9a71012b13ca4d3d0cdc72a177df3ef03b0e76a3";
  const bal_whale_addr = "0x36cc7B13029B5DEe4034745FB4F24034f3F2ffc6";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerWbtcUsdcWethLp", want_addr, bal_addr, true);
});