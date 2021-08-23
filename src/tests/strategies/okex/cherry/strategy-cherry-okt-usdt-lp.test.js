const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCherryOktUsdtLp", () => {
  const want_addr = "0xf3098211d012ff5380a03d80f150ac6e5753caa8";
  const whale_addr = "0x0b52ac11f694e3ff0ed8c58c4769e0268e339b98";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCherryOktUsdtLp", want_addr, true);
});