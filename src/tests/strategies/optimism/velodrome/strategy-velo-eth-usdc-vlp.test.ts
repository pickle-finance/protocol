import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloEthUsdcVlp", () => {
  const want_addr = "0x79c912FEF520be002c2B6e57EC4324e260f38E50";
  const whale_addr = "0xbEbD2364664096c8d194194a209D81b62E37B13E";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 12000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloEthUsdcVlp", want_addr,reward_token_addr, 5);
});
