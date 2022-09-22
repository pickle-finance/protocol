import "@nomicfoundation/hardhat-toolbox";
import { toWei } from "../../../utils/testHelper";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloOpVlp", () => {
  const want_addr = "0xFFD74EF185989BFF8752c818A53a47FC45388F08";
  const whale_addr = "0x924E36660060CaD83Cc438D0E91B0fb00C35eDC6";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(5000, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloOpVlp", want_addr,reward_token_addr, 5);
});
