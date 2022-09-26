const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorFold} = require("../testBehaviorFold");

describe("StrategyUwuDai", () => {
  const want_addr = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const whale_addr = "0xBF293D5138a2a1BA407B43672643434C43827179";
  const reward_addr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  before("Get want token", async () => {
    const [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorFold("StrategyUwuDai", want_addr, reward_addr);
});
