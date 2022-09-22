import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcSnxVlp", () => {
  const want_addr = "0x9056EB7Ca982a5Dd65A584189994e6a27318067D";
  const whale_addr = "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 1850000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcSnxVlp", want_addr, reward_token_addr, 5);
});
