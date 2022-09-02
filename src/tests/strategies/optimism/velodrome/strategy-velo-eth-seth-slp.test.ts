import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloEthSethSlp", () => {
  const want_addr = "0xFd7FddFc0A729eCF45fB6B12fA3B71A575E1966F";
  const whale_addr = "0x39F2A8e0c00d2f5f397A0ba0126544B05B972939";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 6500000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloEthSethSlp", want_addr, reward_token_addr, 5);
});
