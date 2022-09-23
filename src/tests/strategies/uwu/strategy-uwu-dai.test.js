const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorFold} = require("../testBehaviorFold");

describe("StrategyTectonicDai", () => {
  const want_addr = "0xF2001B145b43032AAF5Ee2884e456CCd805F677D";
  const whale_addr = "0xcbDB468a58473e66b557f799208a891B5Be39583";
  const reward_addr = "0xDD73dEa10ABC2Bff99c60882EC5b2B81Bb1Dc5B2";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1000), alice, whale_addr);
  });

  doTestBehaviorFold("StrategyTectonicDai", want_addr, reward_addr);
});
