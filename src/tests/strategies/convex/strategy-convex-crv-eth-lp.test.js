const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyCrvEth", () => {
  const want_addr = "0xEd4064f376cB8d68F770FB1Ff088a3d0F3FF5c4d";
  const whale_addr = "0x279a7dbfae376427ffac52fcb0883147d42165ff";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(500), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCrvEth", want_addr);
});
