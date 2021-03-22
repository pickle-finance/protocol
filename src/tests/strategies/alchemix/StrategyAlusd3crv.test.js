const hre = require("hardhat");
var chaiAsPromised = require("chai-as-promised");
const StrategyCurveAlusd3Crv = hre.artifacts.require("StrategyCurveAlusd3Crv");
const PickleJarAlusd3Crv = hre.artifacts.require("PickleJarAlusd3Crv");
const ControllerV4 = hre.artifacts.require("ControllerV4");

const { assert } = require("chai").use(chaiAsPromised);
const { time } = require("@openzeppelin/test-helpers");

const ERC20_ABI = require("./abi/ERC20.json");

const unlockAccount = async (address) => {
  await hre.network.provider.send("hardhat_impersonateAccount", [address]);
  return hre.ethers.provider.getSigner(address);
};

const toWei = (ethAmount) => {
  return hre.ethers.constants.WeiPerEther.mul(hre.ethers.BigNumber.from(ethAmount));
};

describe("StrategyCurveAlusd3Crv Unit test", () => {
  let strategy, pickleJar, controller;
  const want = "0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c";
  let alusd_3crv, alusd_3crv_whale;
  let deployer, alice, bob;
  let alcx,
    alcx_addr = "0xdbdb4d16eda451d0503b854cf79d55697f90c8df";
  let governance, strategist, devfund, treasury, timelock;

  before("Deploy contracts", async () => {
    [governance, devfund, treasury] = await web3.eth.getAccounts();
    const signers = await hre.ethers.getSigners();
    deployer = signers[0];
    alice = signers[3];
    bob = signers[4];

    strategist = governance;
    timelock = governance;

    controller = await ControllerV4.new(governance, strategist, timelock, devfund, treasury);
    console.log("controller is deployed at =====> ", controller.address);

    strategy = await StrategyCurveAlusd3Crv.new(governance, strategist, controller.address, timelock);
    console.log("Strategy is deployed at =====> ", strategy.address);

    pickleJar = await PickleJarAlusd3Crv.new(want, alcx_addr, governance, timelock, controller.address);
    console.log("pickleJar is deployed at =====> ", pickleJar.address);

    await controller.setJar(want, pickleJar.address, { from: governance });
    await controller.approveStrategy(want, strategy.address, { from: governance });
    await controller.setStrategy(want, strategy.address, { from: governance });

    await strategy.setKeepAlcx("2000", { from: governance });

    alusd_3crv_whale = await unlockAccount("0xBAF18722C137E725327F1376329d3c99F26f6A60");
    alusd_3crv = await hre.ethers.getContractAt(ERC20_ABI, want);
    alcx = await hre.ethers.getContractAt(ERC20_ABI, alcx_addr);

    alusd_3crv.connect(alusd_3crv_whale).transfer(alice.address, toWei(5000));
    assert.equal((await alusd_3crv.balanceOf(alice.address)).toString(), toWei(5000).toString());
    alusd_3crv.connect(alusd_3crv_whale).transfer(bob.address, toWei(3000));
    assert.equal((await alusd_3crv.balanceOf(bob.address)).toString(), toWei(3000).toString());
  });

  it("Should harvest the reward correctly", async () => {
    console.log("\n---------------------------Alice deposit---------------------------------------\n");
    await alusd_3crv.connect(alice).approve(pickleJar.address, toWei(5000));
    await pickleJar.deposit(toWei(5000), { from: alice.address });
    console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());
    await pickleJar.earn({ from: alice.address });

    await harvest();

    console.log("\n---------------------------Bob deposit---------------------------------------\n");
    await alusd_3crv.connect(bob).approve(pickleJar.address, toWei(3000));
    await pickleJar.deposit(toWei(3000), { from: bob.address });
    console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(bob.address)).toString());
    await pickleJar.earn({ from: bob.address });
    await harvest();

    console.log("\n---------------------------Alice withdraw---------------------------------------\n");
    console.log("Redeemable Reward of Strategy =====> ", (await strategy.getRedeemableReward()).toString());

    const _devBefore = await alusd_3crv.balanceOf(devfund);
    let _treasuryBefore = await alcx.balanceOf(treasury);

    console.log("Dev fund balance before ===> ", _devBefore.toString());
    console.log("Treasury balance before ===> ", _treasuryBefore.toString());

    let _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdrawAll({ from: alice.address });

    let _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());

    assert.equal(_alcx_after.gt(_alcx_before), true);

    const _devAfter = await alusd_3crv.balanceOf(devfund);
    let _treasuryAfter = await alcx.balanceOf(treasury);

    console.log("Dev fund balance after ===> ", _devAfter.toString());
    console.log("Treasury balance after ===> ", _treasuryAfter.toString());

    // 0% goes to dev when withdraw
    assert.equal(_devAfter.eq(_devBefore), true);

    // 0% goes to treasury when withdraw
    assert.equal(_treasuryAfter.eq(_treasuryBefore), true);

    console.log("\n---------------------------Bob withdraw---------------------------------------\n");

    console.log("Redeemable Reward of Strategy =====> ", (await strategy.getRedeemableReward()).toString());
    _alcx_before = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdrawAll({ from: bob.address });

    _alcx_after = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());
    assert.equal(_alcx_after.gt(_alcx_before), true);
  });

  it("Should withdraw the want correctly", async () => {
    console.log("\n---------------------------Alice deposit---------------------------------------\n");
    await alusd_3crv.connect(alice).approve(pickleJar.address, toWei(5000));
    await pickleJar.deposit(toWei(5000), { from: alice.address });
    console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());
    await pickleJar.earn({ from: alice.address });

    await harvest();

    console.log("\n---------------------------Bob deposit---------------------------------------\n");
    await alusd_3crv.connect(bob).approve(pickleJar.address, toWei(3000));
    await pickleJar.deposit(toWei(3000), { from: bob.address });
    console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(bob.address)).toString());
    await pickleJar.earn({ from: bob.address });
    await harvest();

    console.log("\n---------------------------Alice withdraw---------------------------------------\n");

    let _jar_before = await alusd_3crv.balanceOf(pickleJar.address);
    await controller.withdrawAll(alusd_3crv.address, { from: governance });
    let _jar_after = await alusd_3crv.balanceOf(pickleJar.address);

    let _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdrawAll({ from: alice.address });

    let _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());

    console.log("\n---------------------------Bob withdraw---------------------------------------\n");

    _alcx_before = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance before =====> ", _alcx_before.toString());

    _jar_before = await alusd_3crv.balanceOf(pickleJar.address);

    await controller.withdrawAll(alusd_3crv.address, { from: governance });

    _jar_after = await alusd_3crv.balanceOf(pickleJar.address);

    await pickleJar.withdrawAll({ from: bob.address });

    _alcx_after = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());
    assert.equal(_alcx_after.gt(_alcx_before), true);
  });

  const harvest = async () => {
    await time.increase(60 * 60 * 24 * 15); //15 days
    const _balance = await strategy.balanceOfPool();
    console.log("Deposited amount of strategy ===> ", _balance.toString());

    let _alcx = await strategy.getHarvestable();
    console.log("Alusd3Crv Farm harvestable of strategy of the first harvest ===> ", _alcx.toString());
    let _alcx2 = await strategy.getAlcxFarmHarvestable();
    console.log("Alcx Farm harvestable of strategy of the first harvest ===> ", _alcx2.toString());

    await strategy.harvest({ from: governance });
    await time.increase(60 * 60 * 24 * 30);

    _alcx = await strategy.getHarvestable();
    console.log("Alusd3Crv Farm harvestable of strategy of the second harvest ===> ", _alcx.toString());

    _alcx2 = await strategy.getAlcxFarmHarvestable();
    console.log("Alcx Farm harvestable of strategy of the second harvest ===> ", _alcx2.toString());

    await strategy.harvest({ from: governance });
  };
});
