import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyBeetxFraxUsdcMaiLp", () => {
  const want_addr = "0x3dC09DB8E571Da76Dd04E9176afc7fEEe0b89106";
  const whale_addr = "0xa6c935eD04dFd5366559cd5fd1C45854fB180589";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(600, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxFraxUsdcMaiLp", want_addr, reward_token_addr, 5);
});
