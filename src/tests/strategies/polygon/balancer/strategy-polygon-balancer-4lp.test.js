const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {doTestBalancerBehaviorBase} = require("./testBalancerBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyBalancerWmaticUsdcWethBalLp", () => {
  const want_addr = "0x0297e37f1873d2dab4487aa67cd56b58e2f27875";
  const whale_addr = "0x415017fbc4BbdaF462b0Ed72193bABE317fbf9f6";
  const bal_addr = "0x9a71012b13ca4d3d0cdc72a177df3ef03b0e76a3";
  const bal_whale_addr = "0xc79dF9fe252Ac55AF8aECc3D93D20b6A4A84527B";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerWmaticUsdcWethBalLp", want_addr, bal_addr, true);
});