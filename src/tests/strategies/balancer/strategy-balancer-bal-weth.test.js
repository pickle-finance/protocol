const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBalancerBehaviorBase} = require("../polygon/balancer/testBalancerBase");

describe("StrategyBalancerBalWethLp", () => {
  const want_addr = "0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56";
  const whale_addr = "0x36cc7B13029B5DEe4034745FB4F24034f3F2ffc6";
  const bal_addr = "0xba100000625a3754423978a60c9317c58a424e3D";
  const bal_whale_addr = "0xfF052381092420B7F24cc97FDEd9C0c17b2cbbB9";

  before("Get want token", async () => {
    const signers = await hre.ethers.getSigners();
    const alice = signers[0];
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
    await getWantFromWhale(bal_addr, toWei(100), alice, bal_whale_addr);
  });

  doTestBalancerBehaviorBase("src/strategies/balancer/strategy-balancer-bal-weth.sol:StrategyBalancerBalWethLp", want_addr, bal_addr, false);
});
