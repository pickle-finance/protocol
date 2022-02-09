const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenWftmUsdcLp", () => {
  const want_addr = "0xcdF68a4d525Ba2E90Fe959c74330430A5a6b8226";
  const whale_addr = "0x8bCa100AC0b9E4C4596320851A14404959381cb9";
  const reward_addr = "0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenWftmUsdcLp", want_addr, reward_addr, 1000, 10000, false, true);
});
