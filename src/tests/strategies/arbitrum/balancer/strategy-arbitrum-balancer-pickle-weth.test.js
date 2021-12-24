const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBalancerBehaviorBase} = require("../../polygon/balancer/testBalancerBaseMultiRewards");

describe("StrategyBalancerPickleWethLp", () => {
  const want_addr = "0xc2F082d33b5B8eF3A7E3de30da54EFd3114512aC";
  const whale_addr = "0xAC39564062A10d247a709bE49742C4622763E1d1";
  const bal_addr = "0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8";
  const pickle_addr = "0x965772e0E9c84b6f359c8597C891108DcF1c5B1A";
  const bal_whale_addr = "0x36cc7B13029B5DEe4034745FB4F24034f3F2ffc6";
  const pickle_whale_addr = "0xbEffe696d7748b946CA44B8b8dfBE837f0A7E41C";

  before("Get want token", async () => {
    const signers = await hre.ethers.getSigners();
    const alice = signers[0];
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
    await getWantFromWhale(pickle_addr, toWei(100), alice, pickle_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerPickleWethLp", want_addr, [bal_addr, pickle_addr], true);
});
