const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {doTestBalancerBehaviorBase} = require("./testBalancerBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyBalancerWbtcUsdcWethLp", () => {
  const want_addr = "0x03cD191F589d12b0582a99808cf19851E468E6B5";
  const whale_addr = "0xA6FbeaaC65DE6d6fC900d95932D9320AaD9128f0";
  const bal_addr = "0x9a71012b13ca4d3d0cdc72a177df3ef03b0e76a3";
  const bal_whale_addr = "0x415017fbc4bbdaf462b0ed72193babe317fbf9f6";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerWbtcUsdcWethLp", want_addr, bal_addr, true);
});