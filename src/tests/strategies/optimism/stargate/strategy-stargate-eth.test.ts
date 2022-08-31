import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyStargateBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyStargateEthOptimism", () => {
  const want_addr = "0xd22363e3762cA7339569F3d33EADe20127D5F98C";
  const whale_addr = "0x1D7C6783328C145393e84fb47a7f7C548f5Ee28d";
  const reward_token_addr = "0x4200000000000000000000000000000000000042";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(9,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyStargateEthOptimism", want_addr, reward_token_addr, 5);
});
