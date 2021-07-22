const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategySorbettoUsdcEthLp", () => {
  const want_addr = "0xd63b340F6e9CCcF0c997c83C8d036fa53B113546";
  const whale = "0xd2be84e68c3b2ceb30dbffffbec18c21a14d7c25";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 16), alice, whale);
  });

  doTestBehaviorBase("StrategySorbettoUsdcEthLp", want_addr);
});
