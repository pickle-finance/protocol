const {expect, deployContract, getContractAt, unlockAccount, toWei} = require("../TestUtil");

describe("StrategySaddleD4 Test", () => {
  const want_addr = "0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A";
  const want_amount = toWei(1000);
  let saddleStrategy;
  let want;
  let timelock;
  let withdrawSaddle;
  const SADDLE_STRATEGY_ADDR = "0x4A974495E20A8E0f5ce1De59eB15CfffD19Bcf8d";

  before("Deploy contracts", async () => {
    saddleStrategy = await getContractAt("StrategySaddleD4", SADDLE_STRATEGY_ADDR);
    withdrawSaddle = await deployContract("WithdrawSaddle");
    want = await getContractAt("ERC20", want_addr);
    timelock = await unlockAccount("0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3");
  });

  it("should withdraw correctly", async () => {
    const prevBalance = await want.balanceOf(SADDLE_STRATEGY_ADDR);
    console.log("Prev Balance => ", prevBalance.toString());
    await saddleStrategy
      .connect(timelock)
      .execute(
        withdrawSaddle.address,
        "0x2e1a7d4d00000000000000000000000000000000000000000000021e19e0c9bab2400000"
      ); //withdrawing 10000 tokens
    const afterBalance = await want.balanceOf(SADDLE_STRATEGY_ADDR);
    console.log("After Balance => ", afterBalance.toString());
    expect(afterBalance.sub(prevBalance)).to.be.gte(toWei(10000), "withdraw failed");
  });
});
