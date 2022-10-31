import "@nomicfoundation/hardhat-toolbox";
import { toWei } from "../../../utils/testHelper";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "../stargate/strategyStargateBase";
import { ethers } from "hardhat";

describe("StrategyHopUsdcOptimism", () => {
  const want_addr = "0x2e17b8193566345a2Dd467183526dEdc42d2d5A8";
  const whale_addr = "0x134A9167E1cA41740D19ad3cB098aa1BF5C5f4eC";
  const reward_token_addr = "0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10_000, 18), alice, whale_addr);
  });

  doTestBehaviorBase(
    "StrategyHopUsdcOptimism",
    want_addr,
    reward_token_addr,
    5
  );
});
