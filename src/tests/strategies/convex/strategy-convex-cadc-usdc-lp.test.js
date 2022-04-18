const {toWei} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {doTestBehaviorBase} = require("../testBehaviorBase");

describe("StrategyCadcUsdc", () => {
  const want_addr = "0x1054Ff2ffA34c055a13DCD9E0b4c0cA5b3aecEB9";
  const whale_addr = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyCadcUsdc", want_addr);
});
