const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategySpiritFtmCre8r", () => {
  const want_addr = "0x459e7c947E04d73687e786E4A48815005dFBd49A";
  const whale_addr = "0xDcF711eb2915518747b50edCccdE429614b6dA81";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(100,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySpiritFtmCre8r", want_addr, true);
});