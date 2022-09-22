import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcMaiSlp", () => {
  const want_addr = "0xd62C9D8a3D4fd98b27CaaEfE3571782a3aF0a737";
  const whale_addr = "0x6DEaC69777aFb8C27f24179AC5EB1795899b42C7";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 4900000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcMaiSlp", want_addr, reward_token_addr, 5);
});
