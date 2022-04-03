const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale, getLpToken} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyDinoWorkUsdcLp", () => {
  const want_addr = "0xAb0454B98dAf4A02EA29292E6A8882FB2C787DD4";
  const whale_addr = "0x7136fbddd4dffa2369a9283b6e90a040318011ca";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 14), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyDinoWorkUsdcLp", want_addr, false, true);
});
