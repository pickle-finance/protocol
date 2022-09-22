import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyBeetxEthIbLp", () => {
  const want_addr = "0xeFb0D9F51EFd52d7589A9083A6d0CA4de416c249";
  const whale_addr = "0x6853EeEF8cABe3E7F4A478b39F1F3FD7e99759b5";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(82, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxEthIbLp", want_addr, reward_token_addr, 5);
});
