const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategySpellEth", () => {
  const want_addr = "0xb5De0C3753b6E1B4dBA616Db82767F17513E6d4E";

  const whale_addr = "0x97767e25b6dc26522a17c6a41e9c206d88e653d6";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpellEthLp", want_addr);
});
