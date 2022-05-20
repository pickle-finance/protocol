const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBalancerBehaviorBase} = require("../../polygon/balancer/testBalancerBase");

describe("StrategyBalancerBalWethLp", () => {
  const want_addr = "0xcC65A812ce382aB909a11E434dbf75B34f1cc59D";
  const whale_addr = "0x242D7Cd78ccE454946f35f0A263b54fBe228852C";
  const bal_addr = "0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8";
  const bal_whale_addr = "0x36cc7B13029B5DEe4034745FB4F24034f3F2ffc6";

  before("Get want token", async () => {
    const signers = await hre.ethers.getSigners();
    const alice = signers[0];
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("src/strategies/arbitrum/balancer/strategy-balancer-bal-weth.sol:StrategyBalancerBalWethLp", want_addr, bal_addr, true);
});
