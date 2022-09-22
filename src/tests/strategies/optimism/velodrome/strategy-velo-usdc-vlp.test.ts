import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcVlp", () => {
  const want_addr = "0xe8537b6FF1039CB9eD0B71713f697DDbaDBb717d";
  const whale_addr = "0x40B322cEDd7AB3C379d65A55C51FE13A0B5A9016";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 8000000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcVlp", want_addr, reward_token_addr, 5);
});
