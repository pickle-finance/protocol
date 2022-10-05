import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyBeetxIbRethLp", () => {
  const want_addr = "0x785F08fB77ec934c01736E30546f87B4daccBe50";
  const whale_addr = "0x4fbe899d37fb7514adf2f41B0630E018Ec275a0C";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(11, 16), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxIbRethLp", want_addr, reward_token_addr, 5);
});
