import "@nomicfoundation/hardhat-toolbox";
import { toWei } from "../../../utils/testHelper";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "../stargate/strategyStargateBase";
import { ethers } from "hardhat";

describe("StrategyHopSnxOptimism", () => {
  const want_addr = "0xe63337211DdE2569C348D9B3A0acb5637CFa8aB3";
  const whale_addr = "0x924AC9910C09A0215b06458653b30471A152022F";
  const reward_token_addr = "0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyHopSnxOptimism", want_addr, reward_token_addr, 5);
});
