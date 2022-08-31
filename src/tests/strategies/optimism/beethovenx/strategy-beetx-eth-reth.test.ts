import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyBeetxEthRethLp", () => {
  const want_addr = "0x4Fd63966879300caFafBB35D157dC5229278Ed23";
  const whale_addr = "0x4fbe899d37fb7514adf2f41B0630E018Ec275a0C";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(2, 16), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxEthRethLp", want_addr, reward_token_addr, 5);
});
