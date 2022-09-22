import "@nomicfoundation/hardhat-toolbox";
import { toWei } from "../../../utils/testHelper";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloEthOpVlp", () => {
  const want_addr = "0xcdd41009E74bD1AE4F7B2EeCF892e4bC718b9302";
  const whale_addr = "0x8E3E62E2229F49ab0A4F5028d05840BB89E20378";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(8,18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloEthOpVlp", want_addr,reward_token_addr, 5);
});