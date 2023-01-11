const {
  expect,
  increaseTime,
  deployContract,
  getContractAt,
  unlockAccount,
  toWei,
  NULL_ADDRESS,
} = require("../../utils/testHelper");

describe("StrategyFraxConvexRsrFraxBP Test", () => {
  let alice;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;
  let want, frax;
  const want_addr = "0x3F436954afb722F5D14D868762a23faB6b0DAbF0";
  const frax_addr = "0x853d955acef822db058eb8505911ed77f175b99e";
  const want_amount = toWei(100);

  before("Deploy contracts", async () => {
    [alice, devfund, treasury] = await hre.ethers.getSigners();
    governance = alice;
    strategist = alice;
    timelock = alice;

    controller = await deployContract(
      "src/polygon/controller-v4.sol:ControllerV4",
      governance.address,
      strategist.address,
      timelock.address,
      devfund.address,
      treasury.address
    );
    console.log("Controller is deployed at ", controller.address);

    strategy = await deployContract(
      "StrategyFraxConvexRsrFraxBP",
      governance.address,
      strategist.address,
      controller.address,
      timelock.address
    );
    console.log("Strategy is deployed at ", strategy.address);

    want = await getContractAt("src/lib/erc20.sol:ERC20", want_addr);
    frax = await getContractAt("src/lib/erc20.sol:ERC20", frax_addr);

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

  it("Should withdraw correctly", async () => {
    const _want = await want.balanceOf(alice.address);
    await want.approve(pickleJar.address, _want);
    await pickleJar.deposit(_want);
    await pickleJar.earn();

    await increaseTime(60 * 60 * 24 * 1);
    console.log("Ratio before harvest: ", (await pickleJar.getRatio()).toString());
    await strategy.harvest();
    console.log("Ratio after harvest: ", (await pickleJar.getRatio()).toString());

    await increaseTime(60 * 60 * 24 * 8);
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
    await increaseTime(60 * 60 * 24 * 1);

    const _before = await pickleJar.balance();
    console.log("Ratio before harvest: ", (await pickleJar.getRatio()).toString());
    await strategy.harvest();
    console.log("Ratio after harvest: ", (await pickleJar.getRatio()).toString());
    const _after = await pickleJar.balance();
    let _treasuryFraxBefore = await frax.balanceOf(treasury.address);

    expect(_treasuryFraxBefore).to.be.gt(0, "20% performance fee is not given");
    expect(_after).to.be.gt(_before);

    await increaseTime(60 * 60 * 24 * 8);

    //withdraw
    const _devBefore = await frax.balanceOf(devfund.address);
    await pickleJar.withdrawAll();
    const _treasuryFraxAfter = await frax.balanceOf(treasury.address);
    const _devAfter = await frax.balanceOf(devfund.address);

    //0% goes to dev
    const _devFund = _devAfter.sub(_devBefore);
    expect(_devFund).to.be.eq(0, "dev've stolen money!!!!!");

    //0% goes to treasury
    const _treasuryFund = _treasuryFraxAfter.sub(_treasuryFraxBefore);
    expect(_treasuryFund).to.be.eq(0, "treasury've stolen money!!!!");
  });

  const getWant = async () => {
    const whale = await unlockAccount("0x561369B3eC94D001031822011B9231e1436bcc78");
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
