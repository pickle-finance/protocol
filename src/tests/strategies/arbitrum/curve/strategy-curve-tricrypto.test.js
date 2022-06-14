const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCurveTricrypto", () => {
  const want_addr = "0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2";
  const whale_addr = "0xf78A4411E98eB741bcB552950034a731b32E2f95";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(5, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCurveTricrypto", want_addr, true);
});