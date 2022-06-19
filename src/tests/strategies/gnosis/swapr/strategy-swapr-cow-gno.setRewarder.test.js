const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("./testBehaviorSwaprSetRewarderBase");

describe("StrategySwaprCowGnoLp", () => {
  const want_addr = "0xDBF14bce36F661B29F6c8318a1D8944650c73F38";
  const whale_addr = "0xF9f12F065499fAC55f031D11D1f1439e4BfA8525";
  const native_token_addr = "0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb";
  const new_rewarder = "0x4c5c6022eb324BDb93a61f8bea64B9f549fC90Fe";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySwaprCowGnoLp", want_addr, native_token_addr, new_rewarder);
});

/* 
old rewarder = 0x95DBc58bCBB3Bc866EdFFC107d65D479d83799E5 (make sure this is the one used in the strategy)
new rewarder = 0x4c5c6022eb324BDb93a61f8bea64B9f549fC90Fe
set blocknumber in hardhat config to 22571491, this block is a few hours before the endingTimestamp in old rewarder, 
swapr rewarders don't accept new stakes after endingTimestamp
make sure the node is an archival one (e.g, https://xdai-archive.blockscout.com)
*/
