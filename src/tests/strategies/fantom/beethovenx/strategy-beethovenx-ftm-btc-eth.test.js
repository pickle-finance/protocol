const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenFtmBtcEthLp", () => {
  const want_addr = "0xd47D2791d3B46f9452709Fa41855a045304D6f9d";
  const whale_addr = "0x9eDd192f2fd97698CD7332Ba2d9dda0c2ddd3E2D";
  
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenFtmBtcEthLp", want_addr, true);
});
