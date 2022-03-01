const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyBeethovenLqdrFtmLp", () => {
  const want_addr = "0x5E02aB5699549675A6d3BEEb92A62782712D0509";
  const whale_addr = "0x73C857d26161c7B11bC1442b304919fCBc5002A7";
  
  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeethovenLqdrFtmLp", want_addr, true);
});
