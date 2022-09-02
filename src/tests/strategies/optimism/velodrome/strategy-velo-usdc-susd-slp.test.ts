import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyVeloBase";
import { ethers } from "hardhat";


describe("StrategyVeloUsdcSusdSlp", () => {
  const want_addr = "0xd16232ad60188B68076a235c65d692090caba155";
  const whale_addr = "0x040479ea0dD9499befF5b8E6b36948c91165EF38";
  const reward_token_addr = "0x3c8B650257cFb5f272f799F5e2b4e65093a11a05";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, 270000000000000, alice, whale_addr);
  });

  doTestBehaviorBase("StrategyVeloUsdcSusdSlp", want_addr, reward_token_addr, 5);
});
