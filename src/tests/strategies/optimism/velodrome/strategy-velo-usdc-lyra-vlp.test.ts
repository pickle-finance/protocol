import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcLyraVlp", () => {
  const want_addr = "0xDEE1856D7B75Abf4C1bDf986da4e1C6c7864d640";
  const whale_addr = "0xf6657BBCfEB5C2746E8C609e35018A5a8caa13fb";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 1055, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcLyraVlp", want_addr, reward_token_addr, 5);
});
