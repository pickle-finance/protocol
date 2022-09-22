const {expect, deployContract, getContractAt, unlockAccount, toWei} = require("../../utils/testHelper");

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
    timelock = await unlockAccount("0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C");
  });

  it("should withdraw correctly", async () => {
    const prevBalance = await want.balanceOf(SADDLE_STRATEGY_ADDR);
    console.log("Prev Balance => ", prevBalance.toString());
    console.log(
      "Prev Balance of gov => ",
      (await want.balanceOf("0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C")).toString()
    );
    await saddleStrategy
      .connect(timelock)
      .execute(
        withdrawSaddle.address,
        "0x2e1a7d4d00000000000000000000000000000000000000000000240dd026f3dbd7d00000"
      ); //withdrawing 10000 tokens
    const afterBalance = await want.balanceOf(SADDLE_STRATEGY_ADDR);
    console.log("After Balance => ", afterBalance.toString());

    console.log(
      "After Balance of gov => ",
      (await want.balanceOf("0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C")).toString()
    );
  });
});
