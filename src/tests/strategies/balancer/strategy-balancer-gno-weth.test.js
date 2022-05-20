const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBalancerBehaviorBase} = require("../polygon/balancer/testBalancerBase");

describe("StrategyBalancerGnoWethLp", () => {
  const want_addr = "0xF4C0DD9B82DA36C07605df83c8a416F11724d88b";
  const whale_addr = "0x009023dA14A3C9f448B75f33cEb9291c21373bD8";
  const bal_addr = "0xba100000625a3754423978a60c9317c58a424e3D";
  const bal_whale_addr = "0xfF052381092420B7F24cc97FDEd9C0c17b2cbbB9";

  before("Get want token", async () => {
    const signers = await hre.ethers.getSigners();
    const alice = signers[0];
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("StrategyBalancerGnoWethLp", want_addr, bal_addr, false);
});
