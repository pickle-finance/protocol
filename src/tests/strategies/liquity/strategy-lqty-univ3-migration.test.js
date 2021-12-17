const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestMigrationBaseWithAddresses} = require("../testMigrationBase");

describe("LQTY Migration", () => {
  const want_addr = "0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D";
  const whale_addr = "0xa9fabaf4a8d01177458e68b8419d138b50ff8ca7";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestMigrationBaseWithAddresses(
    "StrategyLqty", 
    "0x14c0253142cb64D673f7E194C7A97d10261bC442", 
    "0x65B2532474f717D5A8ba38078B78106D56118bbb", 
    "StrategyLqty", 
    "0x9bea066d269d3f585a1eb517f614546fe83e7990",
    want_addr
  );
});
