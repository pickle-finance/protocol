const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBalancerBehaviorBase} = require("../polygon/balancer/testBalancerBase");

describe("StrategyBalancerDaiWethLp", () => {
  const want_addr = "0x0b09deA16768f0799065C475bE02919503cB2a35";
  const whale_addr = "0x49a2DcC237a65Cc1F412ed47E0594602f6141936";
  const bal_addr = "0xba100000625a3754423978a60c9317c58a424e3D";
  const bal_whale_addr = "0xfF052381092420B7F24cc97FDEd9C0c17b2cbbB9";

  before("Get want token", async () => {
    const signers = await hre.ethers.getSigners();
    const alice = signers[0];
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerDaiWethLp", want_addr, bal_addr, false);
});
