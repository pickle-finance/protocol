const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyBeethovenWftmMaticSolAvaxLunaBnbLp", () => {
  const want_addr = "0x9af1F0e9aC9C844A4a4439d446c1437807183075";
  const whale_addr = "0xe341D029A0541f84F53de23E416BeE8132101E48";
  const reward_addr = "0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(15), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenWftmMaticSolAvaxLunaBnbLp", want_addr, reward_addr, 1000, 10000, false, true);
});
