const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorFold} = require("../testBehaviorFold");

describe("StrategyUwuFrax", () => {
  const want_addr = "0x853d955aCEf822Db058eb8505911ED77F175b99e";
  const whale_addr = "0xfcf7C8Fb47855E04a1bee503D1091B65359c6009";
  const reward_addr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  before("Get want token", async () => {
    const [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorFold("StrategyUwuFrax", want_addr, reward_addr);
});
