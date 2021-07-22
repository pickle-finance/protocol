const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategySorbettoEthUsdtLp", () => {
  const want_addr = "0xc4ff55a4329f84f9bf0f5619998ab570481ebb48";
  const whale = "0x07379370e6900e539e5789bdd79dbf74253c290f";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 16), alice, whale);
  });

  doTestBehaviorBase("StrategySorbettoEthUsdtLp", want_addr);
});
