const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorFold} = require("../testBehaviorFold");

describe("StrategyUwuWbtc", () => {
  const want_addr = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
  const whale_addr = "0xbfe5e57fa7a851f1f404e33a57e8fc5bf182df06";
  const reward_addr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  before("Get want token", async () => {
    const [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100, 8), alice, whale_addr);
  });

  doTestBehaviorFold("StrategyUwuWbtc", want_addr, reward_addr);
});
