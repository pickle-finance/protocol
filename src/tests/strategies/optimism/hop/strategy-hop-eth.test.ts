import "@nomicfoundation/hardhat-toolbox";
import { toWei } from "../../../utils/testHelper";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "../stargate/strategyStargateBase";
import { ethers } from "hardhat";

describe("StrategyHopEthOptimism", () => {
  const want_addr = "0x5C2048094bAaDe483D0b1DA85c3Da6200A88a849";
  const whale_addr = "0x09988E9AEb8c0B835619305Abfe2cE68FEa17722";
  const reward_token_addr = "0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyHopEthOptimism", want_addr, reward_token_addr, 5);
});
