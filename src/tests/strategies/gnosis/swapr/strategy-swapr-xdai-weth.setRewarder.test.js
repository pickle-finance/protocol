const {toWei} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {doTestBehaviorBase} = require("./testBehaviorSwaprSetRewarderBase");

describe("StrategySwaprWethXdaiLp", () => {
  const want_addr = "0x1865d5445010E0baf8Be2eB410d3Eae4A68683c2";
  const whale_addr = "0x35E2acD3f46B13151BC941daa44785A38F3BD97A";
  const native_token_addr = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d";
  const new_rewarder = "0x0079B0561DE8bC64f2b5cF00CF6a249C701f8269";

  before("Get want token", async () => {
    [alice] = await hre.ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategySwaprWethXdaiLp", want_addr, native_token_addr);
});

/* 
old rewarder = 0xCB3aAba65599341B5beb24b6001611077c5979E6 (make sure this is the one used in the strategy)
new rewarder = 0x0079B0561DE8bC64f2b5cF00CF6a249C701f8269
set blocknumber in hardhat config to 22571491, this block is a few minutes before the endingTimestamp in old rewarder, 
swapr rewarders don't accept new stakes after endingTimestamp
make sure the node is an archival one (e.g, https://xdai-archive.blockscout.com)
*/
