const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBalancerVstaEthLp", () => {
  const want_addr = "0xC61ff48f94D801c1ceFaCE0289085197B5ec44F0";
  const whale_addr = "0x5f153a7d31b315167fe41da83acba1ca7f86e91d";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBalancerVstaEthLp", want_addr, true);
});