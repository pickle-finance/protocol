const hre = require("hardhat");

var chaiAsPromised = require("chai-as-promised");
const StrategySaddleAlethEth = hre.artifacts.require("StrategySaddleAlethEth");
const PickleJarSymbiotic = hre.artifacts.require("PickleJarSymbiotic");
const ControllerV5 = hre.artifacts.require("ControllerV5");
const ProxyAdmin = hre.artifacts.require("ProxyAdmin");
const AdminUpgradeabilityProxy = hre.artifacts.require("AdminUpgradeabilityProxy");
const {assert} = require("chai").use(chaiAsPromised);

const unlockAccount = async (address) => {
  await hre.network.provider.send("hardhat_impersonateAccount", [address]);
  return hre.ethers.provider.getSigner(address);
};

const toWei = (ethAmount) => {
  return hre.ethers.constants.WeiPerEther.mul(hre.ethers.BigNumber.from(ethAmount));
};

describe("StrategySaddleAlethEth Unit test", () => {
  let strategy, pickleJar;
  let proxyAdmin, controller;
  const want = "0xc9da65931ABf0Ed1b74Ce5ad8c041C4220940368";
  let aleth;
  let deployer, alice, bob, whale;
  let alcx,
    alcx_addr = "0xdbdb4d16eda451d0503b854cf79d55697f90c8df";
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;
  const gaugeAddr = "0x042650a573f3d62d91C36E08045d7d0fd9E63759";

  before("Deploy contracts", async () => {
    [governance, devfund, treasury] = await web3.eth.getAccounts();
    const signers = await hre.ethers.getSigners();
    deployer = signers[0];
    alice = signers[3];
    bob = signers[4];
    john = signers[5];
    whale = signers[6];

    strategist = governance;
    timelock = governance;

    proxyAdmin = await ProxyAdmin.new();
    console.log("ProxyAdmin address =====> ", proxyAdmin.address);
    const controllerImplement = await ControllerV5.new();

    console.log("Controller implementation =====> ", controllerImplement.address);
    const controllerProxy = await AdminUpgradeabilityProxy.new(controllerImplement.address, proxyAdmin.address, []);

    controller = await hre.ethers.getContractAt("ControllerV5", controllerProxy.address);

    await controller.initialize(governance, strategist, timelock, devfund, treasury);
    console.log("controller is deployed at =====> ", controller.address);

    strategy = await StrategySaddleAlethEth.new(governance, strategist, controller.address, timelock);
    console.log("Strategy is deployed at =====> ", strategy.address);

    pickleJar = await PickleJarSymbiotic.new(want, alcx_addr, governance, timelock, controller.address);
    console.log("pickleJar is deployed at =====> ", pickleJar.address);

    // await pickleJar.setGauge(gaugeAddr, {from: governance});

    await controller.setJar(want, pickleJar.address, {from: governance});
    await controller.approveStrategy(want, strategy.address, {
      from: governance,
    });
    await controller.setStrategy(want, strategy.address, {from: governance});

    aleth = await hre.ethers.getContractAt("ERC20", want);
    alcx = await hre.ethers.getContractAt("ERC20", alcx_addr);

    const swapFlashLoan = await hre.ethers.getContractAt("SwapFlashLoan", "0xa6018520EAACC06C30fF2e1B3ee2c7c22e64196a");
    const weth = await hre.ethers.getContractAt("WETH", "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2");
    await weth.connect(whale).deposit({value: toWei(1000)});
    console.log("Whale's weth balance => ", (await weth.balanceOf(whale.address)).toString());
    await weth.connect(whale).approve(swapFlashLoan.address, toWei(1000));
    await swapFlashLoan.connect(whale).addLiquidity([toWei(1000).toString(), 0, 0], 0, 1659116639);

    console.log("Whale's saddle aleth balance => ", (await aleth.balanceOf(whale.address)).toString());

    aleth.connect(whale).transfer(alice.address, toWei(300));
    assert.equal((await aleth.balanceOf(alice.address)).toString(), toWei(300).toString());
    aleth.connect(whale).transfer(bob.address, toWei(400));
    assert.equal((await aleth.balanceOf(bob.address)).toString(), toWei(400).toString());
    aleth.connect(whale).transfer(john.address, toWei(200));
    assert.equal((await aleth.balanceOf(john.address)).toString(), toWei(200).toString());
  });

  beforeEach(async () => {
    preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
  });

  afterEach(async () => {
    await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
  });

  it("Should harvest the reward correctly", async () => {
    console.log("\n---------------------------Alice deposit---------------------------------------\n");
    await aleth.connect(alice).approve(pickleJar.address, toWei(100));
    await pickleJar.deposit(toWei(100), {from: alice.address});
    console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());
    await pickleJar.earn({from: alice.address});

    await pickleJar.transfer(gaugeAddr, toWei(50), {from: alice.address});

    await harvest();

    console.log("\n---------------------------Bob deposit---------------------------------------\n");
    await aleth.connect(bob).approve(pickleJar.address, toWei(200));
    await pickleJar.deposit(toWei(200), {from: bob.address});
    console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(bob.address)).toString());
    await pickleJar.earn({from: bob.address});

    await harvest();

    console.log("\n---------------------------John deposit---------------------------------------\n");
    await aleth.connect(john).approve(pickleJar.address, toWei(150));
    await pickleJar.deposit(toWei(150), {from: john.address});
    await pickleJar.earn({from: john.address});
    console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(john.address)).toString());

    await harvest();

    console.log("\n---------------------------Alice withdraw---------------------------------------\n");
    console.log("Reward balance of strategy ====> ", (await alcx.balanceOf(strategy.address)).toString());
    let _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());
    console.log("\nPending reward of strategy before withdraw ====> ", (await pickleJar.pendingReward()).toString());

    console.log("Alice pending rewards => ", (await pickleJar.pendingRewardOfUser(alice.address)).toString());

    await pickleJar.withdrawAll({from: alice.address});

    let _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());
    console.log("Alice pending rewards => ", (await pickleJar.pendingRewardOfUser(alice.address)).toString());

    assert.equal(_alcx_after.gt(_alcx_before), true);

    await showJarRewardInfo();

    console.log("\nPending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());

    await travelTime(60 * 60 * 24 * 3);
    console.log(
      "Alice pending rewards after 3 days => ",
      (await pickleJar.pendingRewardOfUser(alice.address)).toString()
    );

    console.log("\n---------------------------Alice Redeposit---------------------------------------\n");
    console.log("Alice alcx balance before =====> ", (await alcx.balanceOf(alice.address)).toString());
    await aleth.connect(alice).approve(pickleJar.address, toWei(200));
    await pickleJar.deposit(toWei(200), {from: alice.address});
    await pickleJar.earn({from: alice.address});
    console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());

    console.log("Alice pending rewards => ", (await pickleJar.pendingRewardOfUser(alice.address)).toString());

    console.log("Alice alcx balance after deposit =====> ", (await alcx.balanceOf(alice.address)).toString());
    await travelTime(60 * 60 * 24);

    console.log("\n---------------------------Alice second partial withdraw---------------------------------------\n");
    _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdraw(toWei(100), {from: alice.address});

    _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());

    assert.equal(_alcx_after.gt(_alcx_before), true);

    await showJarRewardInfo();

    console.log("\n---------------------------Alice second all withdraw---------------------------------------\n");
    _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());

    await showJarRewardInfo();

    await pickleJar.withdrawAll({from: alice.address});

    _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());

    assert.equal(_alcx_after.gt(_alcx_before), true);

    await harvest();

    console.log("\n---------------------------Bob withdraw---------------------------------------\n");

    console.log("Reward balance of strategy ====> ", (await alcx.balanceOf(strategy.address)).toString());
    _alcx_before = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance before =====> ", _alcx_before.toString());

    // console.log("Bob pending rewards => ", (await pickleJar.pendingRewardOfUser(bob.address)).toString());
    await pickleJar.withdrawAll({from: bob.address});

    _alcx_after = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());
    assert.equal(_alcx_after.gt(_alcx_before), true);

    await showJarRewardInfo();
    console.log("\nPending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());

    console.log("\n---------------------------John withdraw---------------------------------------\n");
    console.log("Reward balance of strategy ====> ", (await alcx.balanceOf(strategy.address)).toString());

    _alcx_before = await alcx.balanceOf(john.address);
    console.log("John alcx balance before =====> ", _alcx_before.toString());

    console.log("John pending rewards => ", (await pickleJar.pendingRewardOfUser(john.address)).toString());
    await pickleJar.withdrawAll({from: john.address});

    await showJarRewardInfo();
    _alcx_after = await alcx.balanceOf(john.address);
    console.log("John alcx balance after =====> ", (await alcx.balanceOf(john.address)).toString());
    assert.equal(_alcx_after.gt(_alcx_before), true);

    console.log("\nPending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());

    await showJarRewardInfo();

    console.log("\n---------------------------Alice deposit---------------------------------------\n");
    await aleth.connect(alice).approve(pickleJar.address, toWei(300));
    await pickleJar.deposit(toWei(300), {from: alice.address});
    await pickleJar.earn({from: alice.address});
    await showJarRewardInfo();

    console.log("\n---------------------------Bob deposit---------------------------------------\n");
    await aleth.connect(bob).approve(pickleJar.address, toWei(100));
    await pickleJar.deposit(toWei(5), {from: bob.address});
    await pickleJar.earn({from: bob.address});

    await harvest();

    console.log("\n---------------------------Alice Withdraw---------------------------------------\n");
    _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdrawAll({from: alice.address});

    await showJarRewardInfo();
    _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());

    console.log("\n---------------------------Bob Withdraw---------------------------------------\n");
    _alcx_before = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdrawAll({from: bob.address});

    _alcx_after = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());

    console.log("\nPending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());
    await showJarRewardInfo();
  });

  it("Should withdraw the want correctly", async () => {
    console.log("\n---------------------------Alice deposit---------------------------------------\n");
    await aleth.connect(alice).approve(pickleJar.address, toWei(100));
    await pickleJar.deposit(toWei(100), {from: alice.address});
    await pickleJar.earn({from: alice.address});
    console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());

    await harvest();

    console.log("\n---------------------------Bob deposit---------------------------------------\n");
    await aleth.connect(bob).approve(pickleJar.address, toWei(200));
    await pickleJar.deposit(toWei(200), {from: bob.address});
    await pickleJar.earn({from: bob.address});
    console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(bob.address)).toString());

    await harvest();

    console.log("\n---------------------------Alice withdraw---------------------------------------\n");

    await controller.withdrawAll(aleth.address, {from: governance});

    let _alcx_before = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance before =====> ", _alcx_before.toString());

    await pickleJar.withdrawAll({from: alice.address});

    let _alcx_after = await alcx.balanceOf(alice.address);
    console.log("Alice alcx balance after =====> ", _alcx_after.toString());

    console.log("\n---------------------------Bob withdraw---------------------------------------\n");

    _alcx_before = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance before =====> ", _alcx_before.toString());

    _jar_before = await aleth.balanceOf(pickleJar.address);

    await controller.withdrawAll(aleth.address, {from: governance});

    _jar_after = await aleth.balanceOf(pickleJar.address);

    await pickleJar.withdrawAll({from: bob.address});

    _alcx_after = await alcx.balanceOf(bob.address);
    console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());
    assert.equal(_alcx_after.gt(_alcx_before), true);
    console.log("\nStrategy Pending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());
    console.log(
      "\nPickle Jar Pending reward after all withdrawal ====> ",
      (await pickleJar.pendingReward()).toString()
    );
  });
  const showJarRewardInfo = async () => {
    console.log("\nPickle Jar Pending reward ====> ", (await pickleJar.pendingReward()).toString());
    console.log("Pickle Jar curPendingReward ====> ", (await pickleJar.curPendingReward()).toString());
    console.log("Pickle Jar lastPendingReward ====> %s\n", (await pickleJar.lastPendingReward()).toString());
    assert.equal((await pickleJar.pendingReward()).gte(await pickleJar.lastPendingReward()), true);
  };
  const harvest = async () => {
    await travelTime(60 * 60 * 24 * 15); //15 days
    const _balance = await strategy.balanceOfPool();
    console.log("Deposited amount of strategy ===> ", _balance.toString());

    let harvestable = await strategy.getHarvestable();
    console.log("Aleth Farm harvestable of strategy of the first harvest ===> _alcx %s", harvestable.toString());
    let _alcx2 = await strategy.getRewardHarvestable();
    console.log("Alcx Farm harvestable of strategy of the first harvest ===> ", _alcx2.toString());

    await strategy.harvest({from: governance});
    await travelTime(60 * 60 * 24 * 15);

    harvestable = await strategy.getHarvestable();
    console.log("Aleth Farm harvestable of strategy of the second harvest ===> _alcx %s", harvestable.toString());

    _alcx2 = await strategy.getRewardHarvestable();
    console.log("Alcx Farm harvestable of strategy of the second harvest ===> ", _alcx2.toString());

    await strategy.harvest({from: governance});
  };

  const travelTime = async (sec) => {
    await hre.network.provider.send("evm_increaseTime", [sec]);
    await hre.network.provider.send("evm_mine");
  };
});
