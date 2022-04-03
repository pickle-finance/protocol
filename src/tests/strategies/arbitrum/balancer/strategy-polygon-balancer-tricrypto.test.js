const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBalancerBehaviorBase} = require("../../polygon/balancer/testBalancerBase");

describe("StrategyBalancerWbtcWethUsdcLp", () => {
  const want_addr = "0x64541216bAFFFEec8ea535BB71Fbc927831d0595";
  const whale_addr = "0xd2d2f6a38f3a323df87346413269cdb62cbddb71";
  const bal_addr = "0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8";
  const bal_whale_addr = "0xd09ca75315e70bd3988a47958a0c6c5b30b830e1";

  before("Get want token", async () => {
    const signers = await hre.ethers.getSigners();
    const alice = signers[0];
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerWbtcWethUsdcLp", want_addr, bal_addr, true);
});
