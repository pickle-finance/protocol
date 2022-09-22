import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyBeetxEthOpUsdcLp", () => {
  const want_addr = "0x39965c9dAb5448482Cf7e002F583c812Ceb53046";
  const whale_addr = "0x1AC11A2748aF3e46a1696166af8113C5fB83f4fB";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(32, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxEthOpUsdcLp", want_addr, reward_token_addr, 5);
});
