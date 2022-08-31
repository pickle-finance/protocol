import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyStargateBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyStargateUsdcOptimism", () => {
  const want_addr = "0xDecC0c09c3B5f6e92EF4184125D5648a66E35298";
  const whale_addr = "0x32844a824F458f24878515923F1FA120b6b711F2";
  const reward_token_addr = "0x4200000000000000000000000000000000000042";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(17_000,6), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyStargateUsdcOptimism", want_addr, reward_token_addr, 5);
});
