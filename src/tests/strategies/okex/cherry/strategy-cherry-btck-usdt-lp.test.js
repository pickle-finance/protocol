const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");

describe("StrategyCherryBtckUsdtLp", () => {
  const want_addr = "0x94E01843825eF85Ee183A711Fa7AE0C5701A731a";
  const whale_addr = "0xc3e39796ba70f42e8d1fc14faaf73687e931026b";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCherryBtckUsdtLp", want_addr, true);
});