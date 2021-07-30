const {toWei} = require("../../utils/testHelper");
const {getLpToken} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {SUSHI_ROUTER} = require("../../utils/constants");

describe("StrategyMimEth", () => {
  const want_addr = "0x07D5695a24904CC1B6e3bd57cC7780B90618e3c4";

  const whale_addr = "0x97767e25b6dc26522a17c6a41e9c206d88e653d6";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getLpToken(SUSHI_ROUTER, want_addr, toWei(100), alice);
  });

  doTestBehaviorBase("StrategyMimEthLp", want_addr);
});
