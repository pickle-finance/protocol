const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestMigrationBaseWithAddresses} = require("../testMigrationBase");

describe("MIM3CRV Migration", () => {
  const want_addr = "0x5a6A4D54456819380173272A5E8E9B9904BdF41B";
  const whale_addr = "0xdd8e2dd11d38b3e27ad4d7349a61b5c2b5af427a";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(200000), alice, whale_addr);
  });

  doTestMigrationBaseWithAddresses(
    "StrategyMim3crvLp", 
    "0x5dfCe8B1007275d989b18F078c4Af8B19Bd73C00", 
    "0x1Bf62aCb8603Ef7F3A0DFAF79b25202fe1FAEE06", 
    "StrategyConvexMim3Crv", 
    "0x4edbA7b5B715EDac9DAFA1ec4b28131fA3e2B97D", // TO CHANGE AFTER DEPLOYMENT
    want_addr
  );
});
