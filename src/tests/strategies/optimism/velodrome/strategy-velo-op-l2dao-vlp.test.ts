import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyVeloOpL2daoVlp", () => {
  const want_addr = "0xfc77e39De40E54F820E313039207DC850E4C9E60";
  const whale_addr = "0x34e5a165aaB6e7B5dEEB3172BD49B29f2192dC68";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(2800, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloOpL2daoVlp", want_addr, reward_token_addr, 5);
});
