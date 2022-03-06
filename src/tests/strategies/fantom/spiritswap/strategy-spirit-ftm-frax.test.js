const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtmFrax", () => {
  const want_addr = "0x7ed0cdDB9BB6c6dfEa6fB63E117c8305479B8D7D";
  const whale_addr = "0x2e275Ee77D027EC9ac9B296A31085BD240a62B64";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtmFrax", want_addr, true);
});