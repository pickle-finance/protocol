const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyDodoMcbUsdcLp", () => {
  const want_addr = "0x34851ea13bde818b1efe26d31377906b47c9bbe2";

  const whale_addr = "0x1001009911e3fe1d5b45ff8efea7732c33a6c012";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyDodoMcbUsdcLp", want_addr);
});
