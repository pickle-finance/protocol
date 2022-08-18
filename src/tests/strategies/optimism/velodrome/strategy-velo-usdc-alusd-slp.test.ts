import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcAlusdSlp", () => {
  const want_addr = "0xe75a3f4Bf99882aD9f8aeBAB2115873315425D00";
  const whale_addr = "0x1431ba2D4e5C5ed4bf6E8Da41880A7e3B43dA32D";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 31000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcAlusdSlp", want_addr, reward_token_addr, 5);
});
