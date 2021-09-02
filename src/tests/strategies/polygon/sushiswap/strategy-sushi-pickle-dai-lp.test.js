const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");


describe("StrategySushiTrueEthLp", () => {
  const want_addr = "0x57602582eb5e82a197bae4e8b6b80e39abfc94eb";
  const whale_addr = "0x2b23d9b02fffa1f5441ef951b4b95c09faa57eba"

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(15), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySushiPickleDaiLp", want_addr);
});
