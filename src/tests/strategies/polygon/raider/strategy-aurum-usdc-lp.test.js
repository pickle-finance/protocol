const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("../../testBehaviorBase");
const {BigNumber: BN} = require("ethers");
const {POLYGON_SUSHI_ROUTER} = require("../../../utils/constants");

describe("StrategyAurumUsdcLp", () => {
  const want_addr = "0xaBEE7668a96C49D27886D1a8914a54a5F9805041";
  const whale_addr = "0xf7a7bd2c1f3c25b0420e71b7fa85fe03728392b6"

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    const wantInWei = BN.from(2).mul(BN.from(10).pow(16))
    await getWantFromWhale(want_addr, wantInWei, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyAurumUsdcLp", want_addr);
});
 