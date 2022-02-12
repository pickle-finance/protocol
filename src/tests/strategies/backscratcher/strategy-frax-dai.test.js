const {
  toWei,
  deployContract,
  getContractAt,
  increaseTime,
  increaseBlock,
  unlockAccount,
} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {BigNumber: BN} = require("ethers");

describe("StrategyFraxDAI", () => {
  const FRAX_DAI_POOL = "0x97e7d56A0408570bA1a7852De36350f7713906ec";
  const FRAX_DAI_GAUGE = "0xF22471AC2156B489CC4a59092c56713F813ff53e";
  const FraxToken = "0x853d955acef822db058eb8505911ed77f175b99e";
  const DAIToken = "0x6b175474e89094c44da98b954eedeac495271d0f";
  const FXSToken = "0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0";
  const SMARTCHECKER = "0x53c13BA8834a1567474b19822aAD85c6F90D9f9F";

  let alice;
  let frax, dai, fxs, fraxDeployer, escrow;
  let strategy, pickleJar, controller, proxyAdmin, strategyProxy, locker, veFxsVault;
  let smartChecker;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  before("Setup Contracts", async () => {
    [alice, bob, charles, devfund, treasury] = await hre.ethers.getSigners();
    governance = alice;
    strategist = alice;
    timelock = alice;

    proxyAdmin = await deployContract("ProxyAdmin");
    console.log("✅ ProxyAdmin is deployed at ", proxyAdmin.address);

    const controllerImp = await deployContract("ControllerV5");

    const controllerProxy = await deployContract(
      "AdminUpgradeabilityProxy",
      controllerImp.address,
      proxyAdmin.address,
      []
    );

    controller = await getContractAt("ControllerV5", controllerProxy.address);

    await controller.initialize(
      governance.address,
      strategist.address,
      timelock.address,
      devfund.address,
      treasury.address
    );
    console.log("✅ Controller is deployed at ", controller.address);

    const upgradedController = await deployContract("ControllerV7");
    console.log("✅ Controller V6 is deployed at ", upgradedController.address);

    await proxyAdmin.upgrade(controllerProxy.address, upgradedController.address);

    let newController = await getContractAt("ControllerV7", controllerProxy.address);

    locker = await deployContract("FXSLocker");
    console.log("✅ Locker is deployed at ", locker.address);

    escrow = await getContractAt("VoteEscrow", "0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0");

    strategyProxy = await deployContract("StrategyProxy");
    console.log("✅ StrategyProxy is deployed at ", strategyProxy.address);

    await locker.setStrategy(strategyProxy.address);

    await strategyProxy.setLocker(locker.address);

    strategy = await deployContract(
      "StrategyFraxDaiUniV3",
      governance.address,
      strategist.address,
      newController.address,
      timelock.address
    );
    await strategy.connect(governance).setStrategyProxy(strategyProxy.address);
    await strategyProxy.approveStrategy(FRAX_DAI_GAUGE, strategy.address);

    pickleJar = await deployContract(
      "PickleJarUniV3",
      "pickling Frax/DAI Jar",
      "pFraxDAI",
      FRAX_DAI_POOL,
      governance.address,
      timelock.address,
      newController.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await newController.connect(governance).setJar(FRAX_DAI_POOL, pickleJar.address);
    console.log("✅ Set Jar");
    await newController.connect(governance).approveStrategy(FRAX_DAI_POOL, strategy.address);
    console.log("✅ Approve Strategy");
    await newController.connect(governance).setStrategy(FRAX_DAI_POOL, strategy.address);
    console.log("✅ Set Strategy");
    veFxsVault = await deployContract("veFXSVault");
    console.log("✅ veFxsVault is deployed at ", veFxsVault.address);

    await veFxsVault.setProxy(strategyProxy.address);
    await veFxsVault.setFeeDistribution(strategyProxy.address);
    await veFxsVault.setLocker(locker.address);

    await strategyProxy.setFXSVault(veFxsVault.address);

    frax = await getContractAt("ERC20", FraxToken);
    dai = await getContractAt("ERC20", DAIToken);
    fxs = await getContractAt("ERC20", FXSToken);

    await getWantFromWhale(FraxToken, toWei(100000), alice, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(DAIToken, toWei(100000), alice, "0x921760e71fb58dcc8de902ce81453e9e3d7fe253");

    await getWantFromWhale(FraxToken, toWei(100000), bob, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(DAIToken, toWei(100000), bob, "0x921760e71fb58dcc8de902ce81453e9e3d7fe253");

    await getWantFromWhale(FraxToken, toWei(100000), charles, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(DAIToken, toWei(100000), charles, "0x921760e71fb58dcc8de902ce81453e9e3d7fe253");

    await getWantFromWhale(FXSToken, toWei(100000), alice, "0xC30A8c89B02180f8c184c1B8e8f76AF2B9d8f54D");

    // transfer FXS to distributor
    fxs.connect(alice).transfer("0x278dc748eda1d8efef1adfb518542612b49fcd34", toWei(10000));
    // transfer FXS to gauge
    fxs.connect(alice).transfer("0xF22471AC2156B489CC4a59092c56713F813ff53e", toWei(10000));
  });

  it("should harvest correctly", async () => {
    let depositA = toWei(20000);
    let depositB = await getAmountB(depositA);
    let aliceShare, bobShare, charlesShare;

    console.log("=============== Alice deposit ==============");
    await deposit(alice, depositA, depositB);
    await pickleJar.earn();
    await harvest();

    console.log("=============== Bob deposit ==============");
    depositA = toWei(40000);
    depositB = await getAmountB(depositA);

    await deposit(bob, depositA, depositB);
    await pickleJar.earn();
    await harvest();

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    aliceShare = await pickleJar.balanceOf(alice.address);
    console.log("Alice share amount => ", aliceShare.toString());

    console.log("===============Alice partial withdraw==============");
    console.log("Alice dai balance before withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

    console.log("Alice dai balance after withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== Charles deposit ==============");

    depositA = toWei(70000);
    depositB = await getAmountB(depositA);

    await deposit(charles, depositA, depositB);

    console.log("===============Bob withdraw==============");
    console.log("Bob dai balance before withdrawal => ", (await dai.balanceOf(bob.address)).toString());
    console.log("Bob frax balance before withdrawal => ", (await frax.balanceOf(bob.address)).toString());
    await pickleJar.connect(bob).withdrawAll();

    console.log("Bob dai balance after withdrawal => ", (await dai.balanceOf(bob.address)).toString());
    console.log("Bob frax balance after withdrawal => ", (await frax.balanceOf(bob.address)).toString());

    await harvest();
    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    await pickleJar.earn();

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== Controller withdraw ===============");
    console.log("PickleJar dai balance before withdrawal => ", (await dai.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance before withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    await controller.withdrawAll(FRAX_DAI_POOL);

    console.log("PickleJar dai balance after withdrawal => ", (await dai.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance after withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    console.log("===============Alice Full withdraw==============");

    console.log("Alice dai balance before withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    await pickleJar.connect(alice).withdrawAll();

    console.log("Alice dai balance after withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    // await harvest();
    // await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== charles withdraw ==============");
    console.log("Charles dai balance before withdrawal => ", (await dai.balanceOf(charles.address)).toString());
    console.log("Charles frax balance before withdrawal => ", (await frax.balanceOf(charles.address)).toString());
    await pickleJar.connect(charles).withdrawAll();

    console.log("Charles dai balance after withdrawal => ", (await dai.balanceOf(charles.address)).toString());
    console.log("Charles frax balance after withdrawal => ", (await frax.balanceOf(charles.address)).toString());

    // console.log("=============== Alice redeposit ==============");
    // depositA = toWei(50000);
    // depositB = await getAmountB(depositA);

    // await deposit(alice, depositA, depositB);
    // await pickleJar.earn();

    // await harvest();
    // await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    // console.log("===============Alice final withdraw==============");

    // console.log("Alice dai balance before withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    // console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    // await pickleJar.connect(alice).withdrawAll();

    // console.log("Alice dai balance after withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    // console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    console.log("------------------ Finished -----------------------");

    console.log("Treasury dai balance => ", (await dai.balanceOf(treasury.address)).toString());
    console.log("Treasury frax balance => ", (await frax.balanceOf(treasury.address)).toString());

    console.log("Strategy dai balance => ", (await dai.balanceOf(strategy.address)).toString());
    console.log("Strategy frax balance => ", (await frax.balanceOf(strategy.address)).toString());
    console.log("Strategy fxs balance => ", (await fxs.balanceOf(strategy.address)).toString());

    console.log("PickleJar dai balance => ", (await dai.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance => ", (await frax.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar fxs balance => ", (await fxs.balanceOf(pickleJar.address)).toString());

    console.log("Locker dai balance => ", (await dai.balanceOf(locker.address)).toString());
    console.log("Locker frax balance => ", (await frax.balanceOf(locker.address)).toString());
    console.log("Locker fxs balance => ", (await fxs.balanceOf(locker.address)).toString());

    console.log("StrategyProxy dai balance => ", (await dai.balanceOf(strategyProxy.address)).toString());
    console.log("StrategyProxy frax balance => ", (await frax.balanceOf(strategyProxy.address)).toString());
    console.log("StrategyProxy fxs balance => ", (await fxs.balanceOf(strategyProxy.address)).toString());
  });
  /*
  it("should withdraw correctly", async () => {
    let depositA = toWei(50000);
    let depositB = await getAmountB(depositA);

    console.log("=============== Alice deposit ==============");
    await deposit(alice, depositA, depositB);
    await pickleJar.earn();
    await harvest();

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days
    console.log("PickleJar dai balance before withdrawal => ", (await dai.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance before withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    await controller.withdrawAll(FRAX_DAI_POOL);

    console.log("PickleJar dai balance after withdrawal => ", (await dai.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance after withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    console.log("Alice dai balance before withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    await pickleJar.connect(alice).withdrawAll();

    console.log("Alice dai balance after withdrawal => ", (await dai.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());
  });
*/
  const deposit = async (user, depositA, depositB) => {
    await dai.connect(user).approve(pickleJar.address, depositA);
    await frax.connect(user).approve(pickleJar.address, depositB);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, depositB);
  };

  const harvest = async () => {
    console.log("============ Harvest Started ==============");

    console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 14); //travel 30 days
    await increaseBlock(1000);
    await strategy.harvest();
    console.log("Ratio after harvest => ", (await pickleJar.getRatio()).toString());
    console.log("============ Harvest Ended ==============");
  };

  const getAmountB = async (amountA) => {
    const proportion = await pickleJar.getProportion();
    const amountB = amountA.mul(proportion).div(hre.ethers.BigNumber.from("1000000000000000000"));
    return amountB;
  };

  // beforeEach(async () => {
  //   preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
  // });

  // afterEach(async () => {
  //   await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
  // });
});
