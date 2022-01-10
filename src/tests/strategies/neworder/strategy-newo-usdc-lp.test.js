const {toWei} = require("../../utils/testHelper");
const {getLpToken, getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {BigNumber: BN} = require("ethers");

describe("StrategyNewoUsdcLp", () => {
  const want_addr = "0xB264dC9D22ece51aAa6028C5CBf2738B684560D6";
  const whale_addr = "0xc68e2a702c7f2ecfaf6e4e885da1ceb2f767183a";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, BN.from("9").mul(BN.from(10).pow(14)), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyNewoUsdcLp", want_addr);
});
