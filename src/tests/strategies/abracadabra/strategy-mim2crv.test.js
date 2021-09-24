const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyMim2Crv", () => {
  const want_addr = "0x30dF229cefa463e991e29D42DB0bae2e122B2AC7";
  const whale_addr = "0xdb4279a3b63335cc78666326cb1c0115e46c0058";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyAbraMim2Crv", want_addr);
});
