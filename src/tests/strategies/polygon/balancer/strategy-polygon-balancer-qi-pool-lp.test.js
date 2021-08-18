const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {doTestBalancerBehaviorBase} = require("./testBalancerBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyBalancerWmaticUsdcQiBalMimaticLp", () => {
  const want_addr = "0xf461f2240B66D55Dcf9059e26C022160C06863BF";
  const whale_addr = "0x67941779E59CEFDBc61Af9Cb047d44C173301795";
  const bal_addr = "0x9a71012b13ca4d3d0cdc72a177df3ef03b0e76a3";
  const bal_whale_addr = "0xc79dF9fe252Ac55AF8aECc3D93D20b6A4A84527B";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerWmaticUsdcQiBalMimaticLp", want_addr, bal_addr, true);
});