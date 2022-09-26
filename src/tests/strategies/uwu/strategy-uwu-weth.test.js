const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorFold} = require("../testBehaviorFold");

describe("StrategyUwuWeth", () => {
  const want_addr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const whale_addr = "0x44cc771fbe10dea3836f37918cf89368589b6316";
  const reward_addr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  before("Get want token", async () => {
    const [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100), alice, whale_addr);
  });

  doTestBehaviorFold("StrategyUwuWeth", want_addr, reward_addr);
});
