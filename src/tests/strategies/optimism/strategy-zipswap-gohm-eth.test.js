const { toWei } = require("../../utils/testHelper");
const { getWantFromWhale } = require("../../utils/setupHelper");
const { doTestBehaviorBase } = require("../testBehaviorBase");
const hre = require("hardhat");

describe("StrategyZipEthgOHMLp", () => {
  const want_addr = "0x3f6da9334142477718bE2ecC3577d1A28dceAAe1";
  const whale_addr = "0xD34216F24DaC965F9CC9a9762194d1CBcD58e5a1";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyZipEthgOHMLp", want_addr, true);
});