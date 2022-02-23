const {toWei} = require("../../../../utils/testHelper");
const {getWantFromWhale} = require("../../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../../testBehaviorBase");

describe("StrategyLqdrDeusWftm", () => {
  const want_addr = "0x2599Eba5fD1e49F294C76D034557948034d6C96E";
  const whale_addr = "0x49E59dE5DBF06ED83116AfAA0570Bfe13a8D5bA7";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyLqdrDeusWftm", want_addr, true);
});