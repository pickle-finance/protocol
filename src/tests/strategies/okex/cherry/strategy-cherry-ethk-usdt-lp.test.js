const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCherryEthkUsdtLp", () => {
  const want_addr = "0x407F7a2F61E5bAB199F7b9de0Ca330527175Da93";
  const whale_addr = "0xe0b56628ed832aB39C915e8941880559a252cF75";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCherryEthkUsdtLp", want_addr, true);
});