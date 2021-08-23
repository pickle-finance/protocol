const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCherryUsdtUsdcLp", () => {
  const want_addr = "0xb6fCc8CE3389Aa239B2A5450283aE9ea5df9d1A9";
  const whale_addr = "0xf3e0974a5fecfe4173e454993406243b2188eeed";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCherryUsdtUsdcLp", want_addr, true);
});