import "@nomicfoundation/hardhat-toolbox";
import { getWantFromWhale } from "../../../utils/setupHelper";
import { doTestBehaviorBase } from "./strategyBeetxBase";
import { ethers } from "hardhat";
import { toWei } from "../../TestUtil";


describe("StrategyBeetxBalOpLp", () => {
  const want_addr = "0xd6E5824b54f64CE6f1161210bc17eeBfFC77E031";
  const whale_addr = "0xa760420793dA1a539198EF2617990D67A213Ff0e";
  const reward_token_addr = "0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921";

  before("Get want token", async () => {
    const [alice] = await ethers.getSigners();
    await getWantFromWhale(want_addr, toWei(1200, 18), alice, whale_addr);
  });

  doTestBehaviorBase("StrategyBeetxBalOpLp", want_addr, reward_token_addr, 5);
});
