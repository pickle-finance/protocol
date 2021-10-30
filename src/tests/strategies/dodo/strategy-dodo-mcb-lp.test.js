const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyDodoMcbUsdcLp", () => {
  const want_addr = "0x34851ea13bde818b1efe26d31377906b47c9bbe2";

  const whale_addr = "0x1825b9faf7c3ab0efbbd927cd1a8fe2c86c933fd";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyDodoMcbUsdcLp", want_addr);
});
