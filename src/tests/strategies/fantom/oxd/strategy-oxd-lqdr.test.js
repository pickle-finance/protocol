const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyOxdLqdr", () => {
  const want_addr = "0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9";
  const whale_addr = "0x078e88e465f2a430399e319d57543a7a76e97668";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(3000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyOxdLqdr", want_addr, true);
});