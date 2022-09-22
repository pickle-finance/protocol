import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloOpUsdcVlp", () => {
  const want_addr = "0x47029bc8f5CBe3b464004E87eF9c9419a48018cd";
  const whale_addr = "0x0333E3a9f758C43667b5FbBdB0d70173EAb34201";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 200000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloOpUsdcVlp", want_addr,reward_token_addr, 5);
});