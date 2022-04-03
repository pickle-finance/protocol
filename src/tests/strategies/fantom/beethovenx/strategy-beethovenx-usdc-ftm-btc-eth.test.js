const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenUsdcFtmBtcEthLp", () => {
  const want_addr = "0xf3A602d30dcB723A74a0198313a7551FEacA7DAc";
  const whale_addr = "0x1Bf3830Ec2Dd2034CF75049b16de186336EE368D";
  
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenUsdcFtmBtcEthLp", want_addr, true);
});
