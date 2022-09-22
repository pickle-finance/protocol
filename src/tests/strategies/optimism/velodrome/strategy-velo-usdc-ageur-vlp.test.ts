import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcAgeurVlp", () => {
  const want_addr = "0x7866C6072B09539fC0FDE82963846b80203d7beb";
  const whale_addr = "0x603ffa42b2Ce5E22C1a2a7dafbD014F60567ebBC";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 66000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcAgeurVlp", want_addr, reward_token_addr, 5);
});
