const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");
const {UNI_ROUTER} = require("../../utils/constants");


describe("StrategyLooksStaking", () => {
  const want_addr = "0xf4d2888d29D722226FafA5d9B24F9164c092421E";
  const whale_addr = "0x44f6827aa307f4d7faeb64be47543647b3a871db";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLooksStaking", want_addr, true);
});
