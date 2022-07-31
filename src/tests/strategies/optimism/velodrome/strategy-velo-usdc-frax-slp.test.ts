import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcFraxSlp", () => {
  const want_addr = "0xAdF902b11e4ad36B227B84d856B229258b0b0465";
  const whale_addr = "0x9702219A295801852357994DbfAEA84fcE3590Ca";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 92900, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcFraxSlp", want_addr, reward_token_addr, 5);
});
