import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloEthAlienVlp", () => {
  const want_addr = "0x3EEc44e94ee86ce79f34Bb26dc3CdbbEe18d6d17";
  const whale_addr = "0xe247340f06FCB7eb904F16a48C548221375b5b96";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 110000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloEthAlienVlp", want_addr,reward_token_addr, 5);
});
