const {
  expect,
  increaseTime,
  deployContract,
  getContractAt,
  unlockAccount,
  toWei,
  NULL_ADDRESS,
} = require("../TestUtil");

describe("StrategySaddleD4 Test", () => {
  let alice;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;
  let want;
  const want_addr = "0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A";
  const want_amount = toWei(10);

  before("Deploy contracts", async () => {
    [alice, devfund, treasury] = await hre.ethers.getSigners();
    governance = alice;
    strategist = alice;
    timelock = alice;

    controller = await deployContract(
      "ControllerV4",
      governance.address,
      strategist.address,
      timelock.address,
      devfund.address,
      treasury.address
    );
    console.log("Controller is deployed at ", controller.address);

    strategy = await deployContract(
      "StrategySaddleD4",
      governance.address,
      strategist.address,
      controller.address,
      timelock.address
    );
    console.log("Strategy is deployed at ", strategy.address);

    want = await getContractAt("ERC20", want_addr);

    pickleJar = await deployContract(
      "PickleJar",
      want.address,
      governance.address,
      timelock.address,
      controller.address
    );
    console.log("PickleJar is deployed at ", pickleJar.address);

    await controller.setJar(want.address, pickleJar.address);
    await controller.approveStrategy(want.address, strategy.address);
    await controller.setStrategy(want.address, strategy.address);
    // get want token
    await getWant();
  });

  it("Should set the timelock correctly", async () => {
    expect(await strategy.timelock()).to.be.eq(timelock.address, "timelock is incorrect");
    await strategy.setTimelock(NULL_ADDRESS);
    expect(await strategy.timelock()).to.be.eq(NULL_ADDRESS, "timelock is incorrect");
  });

  it("Should withdraw correctly", async () => {
    const _want = await want.balanceOf(alice.address);
    await want.approve(pickleJar.address, _want);
    await pickleJar.deposit(_want);

    await pickleJar.earn();
    await increaseTime(60 * 60 * 24 * 15); //travel 15 days
    await strategy.harvest();

    let _before = await want.balanceOf(pickleJar.address);
    await controller.withdrawAll(want.address);
    let _after = await want.balanceOf(pickleJar.address);
    expect(_after).to.be.gt(_before, "controller withdrawAll failed");

    _before = await want.balanceOf(alice.address);
    await pickleJar.withdrawAll();
    _after = await want.balanceOf(alice.address);

    expect(_after).to.be.gt(_before, "picklejar withdrawAll failed");
    expect(_after).to.be.gt(_want, "no interest earned");
  });

  it("Should harvest correctly", async () => {
    const _want = await want.balanceOf(alice.address);
    await want.approve(pickleJar.address, _want);
    await pickleJar.deposit(_want);

    await pickleJar.earn();
    await increaseTime(60 * 60 * 24 * 15); //travel 15 days

    const _before = await pickleJar.balance();
    const _treasuryBefore = await want.balanceOf(treasury.address);
    await strategy.harvest();
    const _after = await pickleJar.balance();
    const _treasuryAfter = await want.balanceOf(treasury.address);

    //20% performance fee is given
    const earned = _after.sub(_before).mul(1000).div(800);
    const earnedRewards = earned.mul(200).div(1000);
    const actualRewardsEarned = _treasuryAfter.sub(_treasuryBefore);

    expect(earnedRewards).to.be.eqApprox(actualRewardsEarned, "20% performance fee is not given");

    //withdraw
    const _devBefore = await want.balanceOf(devfund.address);
    _treasuryBefore = await want.balanceOf(treasury.address);
    await pickleJar.withdrawAll();
    const _devAfter = await want.balanceOf(devfund.address);
    _treasuryAfter = await want.balanceOf(treasury.address);

    //0% goes to dev
    const _devFund = _devAfter.sub(_devBefore);
    expect(_devFund).to.be.eq(0, "dev've stolen money!!!!!");

    //0% goes to treasury
    const _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
    expect(_treasuryFund).to.be.eq(0, "treasury've stolen money!!!!");
  });

  const getWant = async () => {
    const whale = await unlockAccount("0xe9b05db21f255544721d0a58c1e9963d53d8bb95");
    await want.connect(whale).transfer(alice.address, want_amount);
    const _balance = await want.balanceOf(alice.address);
    expect(_balance).to.be.eq(want_amount, "get want failed");
  };

  beforeEach(async () => {
    preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
  });

  afterEach(async () => {
    await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
  });
});
