const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestMigrationBaseWithAddresses} = require("../testMigrationBase");

describe("STETH Migration", () => {
  const want_addr = "0x06325440D014e39736583c165C2963BA99fAf14E";
  const whale_addr = "0x8835a35023c2fcf105e1f232e600385ed6db9bc6";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestMigrationBaseWithAddresses(
    "StrategyCurveSteCRV", 
    "0x350c4f7a669dc263ec1838fa105172e1d96e8259", 
    "0x77C8A58D940a322Aea02dBc8EE4A30350D4239AD", 
    "StrategyConvexSteCRV", 
    want_addr
  );
});
