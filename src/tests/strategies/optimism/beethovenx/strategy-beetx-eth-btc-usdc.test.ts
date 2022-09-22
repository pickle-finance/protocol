import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../../utils/testHelper";


describe("StrategyBeetxEthBtcUsdcLp", () => {
  const want_addr = "0x5028497af0c9a54ea8C6D42a054c0341B9fc6168";
  const whale_addr = "0xFEBF8038dA09FE4d48F1beAcA5B630f5418e67fa";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(10, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxEthBtcUsdcLp", want_addr, reward_token_addr, 5);
});
