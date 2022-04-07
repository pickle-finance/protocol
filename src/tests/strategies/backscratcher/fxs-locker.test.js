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
const {expect} = require("chai");

describe("FXSLocker test", () => {
  const FRAX_DAI_POOL = "0x97e7d56A0408570bA1a7852De36350f7713906ec";
  const FRAX_DAI_GAUGE = "0xF22471AC2156B489CC4a59092c56713F813ff53e";
  const FraxToken = "0x853d955acef822db058eb8505911ed77f175b99e";
  const DAIToken = "0x6b175474e89094c44da98b954eedeac495271d0f";
  const FXSToken = "0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0";
  const SMARTCHECKER = "0x53c13BA8834a1567474b19822aAD85c6F90D9f9F";
  const FXS_DISTRIBUTOR = "0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872";
  const FXS_WHALE = "0xF977814e90dA44bFA03b6295A0616a897441aceC";

  let alice, bob;
  let frax, dai, fxs, fraxDeployer, escrow;
  let strategy, pickleJar, controller, proxyAdmin, strategyProxy, locker, veFxsVault;
  let smartChecker;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;
  let fxsBefore, fxsAfter, fxsAfterFlywheel;

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
    console.log("✅ Controller V7 is deployed at ", upgradedController.address);

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
      "PickleJarStablesUniV3",
      "pickling Frax/DAI Jar",
      "pFraxDAI",
      FRAX_DAI_POOL,
      governance.address,
      timelock.address,
      newController.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await newController.connect(governance).setJar(FRAX_DAI_POOL, pickleJar.address);
    await newController.connect(governance).approveStrategy(FRAX_DAI_POOL, strategy.address);
    await newController.connect(governance).setStrategy(FRAX_DAI_POOL, strategy.address);

    veFxsVault = await deployContract("veFXSVault");
    console.log("✅ veFxsVault is deployed at ", veFxsVault.address);

    await veFxsVault.setProxy(strategyProxy.address);
    await veFxsVault.setFeeDistribution(strategyProxy.address);
    await veFxsVault.setLocker(locker.address);
    await strategy.connect(timelock).setBackscratcher(veFxsVault.address);

    await strategyProxy.setFXSVault(veFxsVault.address);

    frax = await getContractAt("ERC20", FraxToken);
    dai = await getContractAt("ERC20", DAIToken);
    fxs = await getContractAt("ERC20", FXSToken);

    fraxDeployer = await unlockAccount("0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27");
    smartChecker = await getContractAt("ISmartWalletChecker", SMARTCHECKER);
    veFXSFeeDistributor = await getContractAt("veFXSYieldDistributorV4", FXS_DISTRIBUTOR);

    await getWantFromWhale(FXSToken, toWei(490000), alice, FXS_WHALE);
    await getWantFromWhale(FXSToken, toWei(1000000), bob, FXS_WHALE);
    const whale = await unlockAccount(FXS_WHALE);
    await fxs.connect(whale).transfer("0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27", toWei(490000));

    // Create FXS lock
    await smartChecker.connect(fraxDeployer).approveWallet(locker.address);
    await fxs.connect(alice).transfer(locker.address, toWei(1));

    const now = Math.round(new Date().getTime() / 1000);
    const ONEYEAR = 60 * 60 * 24 * 365;

    // Initially lock for 2 years
    await locker.connect(governance).createLock(toWei(1), now + ONEYEAR);

    // transfer FXS to gauge distributor
    await fxs.connect(alice).transfer("0x278dc748eda1d8efef1adfb518542612b49fcd34", toWei(100000));
    // transfer FXS to gauge
    await fxs.connect(alice).transfer("0xF22471AC2156B489CC4a59092c56713F813ff53e", toWei(100000));

    // Make a deposit into veFXSVault
    await fxs.connect(alice).approve(veFxsVault.address, toWei(9000));
    await veFxsVault.connect(alice).deposit(toWei(9000));

    // Increase lock time by 6 months
    await locker.execute("0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872", 0, "0xc2c4c5c1");

    fxsBefore = await fxs.balanceOf(alice.address);

    await veFXSFeeDistributor.connect(fraxDeployer).toggleRewardNotifier("0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27");
    await fxs.connect(fraxDeployer).approve(veFXSFeeDistributor.address, toWei(100000));
    await veFXSFeeDistributor.connect(fraxDeployer).notifyRewardAmount(toWei(100000));

    await increaseTime(60 * 60 * 24 * 8); //travel 30 days
    await increaseBlock(100);
  });

  it("Should extend lock time and claim FXS", async () => {
    // Initial lock end date

    const locked_end = await escrow.locked__end(locker.address);
    console.log("locked_end => ", locked_end.toString());

    // Increase lock time by 6 months
    await locker.execute(
      "0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0",
      0,
      "0xeff7a6120000000000000000000000000000000000000000000000000000000065B9C58C"
    );
    const locked_end_extended = await escrow.locked__end(locker.address);
    console.log("locked_end_extended => ", locked_end_extended.toString());
    await veFxsVault.connect(alice).claim();

    fxsAfter = await fxs.balanceOf(alice.address);

    console.log("FXS balance before claim: ", fxsBefore.toString());
    console.log("FXS balance after claim: ", fxsAfter.toString());
    console.log("FXS balance in backscratcher: ", (await fxs.balanceOf(veFxsVault.address)).toString());
    expect(locked_end_extended.gt(locked_end));
    expect(fxsAfter.gt(fxsBefore));
  });

  it("Should have greater rewards with strategy flywheel", async () => {
    await getWantFromWhale(FraxToken, toWei(100000), alice, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(DAIToken, toWei(100000), alice, "0x921760e71fb58dcc8de902ce81453e9e3d7fe253");

    let depositA = toWei(20000);
    let depositB = await getAmountB(depositA);

    console.log("=============== Alice deposit ==============");
    await deposit(alice, depositA, depositB);
    await pickleJar.earn();
    console.log("FXS balance in backscratcher before harvest: ", (await fxs.balanceOf(veFxsVault.address)).toString());
    await harvest();
    console.log("FXS balance in backscratcher after harvest: ", (await fxs.balanceOf(veFxsVault.address)).toString());
    await veFxsVault.connect(alice).claim();
    console.log("FXS balance for Alice intermediate: ", (await fxs.balanceOf(alice.address)).toString());

    fxsAfterFlywheel = await fxs.balanceOf(alice.address);
    console.log("FXS balance before claim: ", fxsBefore.toString());
    console.log("FXS balance after claim: ", fxsAfterFlywheel.toString());
    console.log("FXS balance in backscratcher after claim: ", (await fxs.balanceOf(veFxsVault.address)).toString());
    expect(fxsAfterFlywheel.gt(fxsAfter));
  });

  const deposit = async (user, depositA, depositB) => {
    await dai.connect(user).approve(pickleJar.address, depositA);
    await frax.connect(user).approve(pickleJar.address, depositB);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, depositB);
  };

  it("Should facilitate multiple users locking", async () => {
    const lockedBefore = await escrow.balanceOf(locker.address);

    await fxs.connect(fraxDeployer).approve(veFXSFeeDistributor.address, toWei(100000));
    await veFXSFeeDistributor.connect(fraxDeployer).notifyRewardAmount(toWei(100000));

    console.log("FXS locked BEFORE additional lock: ", lockedBefore.toString());
    console.log(
      "FXS balance of FxsVault before lock (should be ZERO): ",
      (await fxs.balanceOf(veFxsVault.address)).toString()
    );

    console.log("Bob deposits additional 5000 FXS into locker...");

    // Make a deposit into veFXSVault
    await fxs.connect(bob).approve(veFxsVault.address, toWei(5000));
    await veFxsVault.connect(bob).deposit(toWei(5000));

    const lockedAfter = await escrow.balanceOf(locker.address);

    console.log("FXS balance of FxsVault after lock: ", (await fxs.balanceOf(veFxsVault.address)).toString());
    console.log("FXS locked AFTER additional lock: ", lockedAfter.toString());
    console.log("Alice pToken balance: ", (await veFxsVault.balanceOf(alice.address)).toString());
    console.log("Bob pToken balance: ", (await veFxsVault.balanceOf(bob.address)).toString());

    await increaseTime(60 * 60 * 24 * 8); //travel 15 days
    await increaseBlock(100);

    const aliceFXSBefore = (await fxs.balanceOf(alice.address)).toString();
    const bobFXSBefore = (await fxs.balanceOf(bob.address)).toString();
    console.log("Alice FXS balance before claim: ", aliceFXSBefore);
    console.log("Bob FXS balance before claim: ", bobFXSBefore);
    await veFxsVault.connect(alice).claim();
    await veFxsVault.connect(bob).claim();
    const aliceFXSAfter = (await fxs.balanceOf(alice.address)).toString();
    const bobFXSAfter = (await fxs.balanceOf(bob.address)).toString();
    console.log("Alice FXS balance after claim: ", aliceFXSAfter);
    console.log("Bob FXS balance after claim: ", bobFXSAfter);

    expect(lockedAfter.gt(lockedBefore));
  });

  const harvest = async () => {
    console.log("============ Harvest Started ==============");

    console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 8); //travel 14 days
    await increaseBlock(100);
    await strategy.harvest();
    console.log("Ratio after harvest => ", (await pickleJar.getRatio()).toString());
    console.log("============ Harvest Ended ==============");
  };

  const getAmountB = async (amountA) => {
    const proportion = await pickleJar.getProportion();
    const amountB = amountA.mul(proportion).div(hre.ethers.BigNumber.from("1000000000000000000"));
    return amountB;
  };

  beforeEach(async () => {
    preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
  });

  afterEach(async () => {
    await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
  });
});
