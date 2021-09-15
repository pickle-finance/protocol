const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyLqty", () => {
  const want_addr = "0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D";
  const whale_addr = "0x57ca561798413a20508B6bC997481E784F3E6e5f";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqty", want_addr);
});
