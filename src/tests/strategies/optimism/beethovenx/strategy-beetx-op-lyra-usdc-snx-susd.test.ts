import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";

// Set blockNumber: 16149920 in hardhat.config
describe("StrategyBeetxOpLyraUsdcSnxSusdLp", () => {
  const want_addr = "0x7Ef99013E446dDCe2486b8E04735b7019a115e6F";
  const whale_addr = "0x3465D93b84Ed7557d42d84CB7c8999Fc3DB2113d";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(395, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxOpLyraUsdcSnxSusdLp", want_addr, reward_token_addr, 5);
});

