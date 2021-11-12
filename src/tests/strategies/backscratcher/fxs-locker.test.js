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
  const FXS_DISTRIBUTOR = "0xed2647Bbf875b2936AAF95a3F5bbc82819e3d3FE";

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

    const controllerImp = await deployContract("ControllerV6");

    const controllerProxy = await deployContract(
      "AdminUpgradeabilityProxy",
      controllerImp.address,
      proxyAdmin.address,
      []
    );
    controller = await getContractAt("ControllerV6", controllerProxy.address);

    await controller.initialize(
      governance.address,
      strategist.address,
      timelock.address,
      devfund.address,
      treasury.address
    );
    console.log("✅ Controller is deployed at ", controller.address);

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
      controller.address,
      timelock.address
    );
    await strategy.connect(governance).setStrategyProxy(strategyProxy.address);
    await strategyProxy.approveStrategy(FRAX_DAI_GAUGE, strategy.address);

    pickleJar = await deployContract(
      "PickleJarUniV3",
      "pickling Frax/DAI Jar",
      "pFraxDAI",
      FRAX_DAI_POOL,
      -50,
      50,
      governance.address,
      timelock.address,
      controller.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await controller.connect(governance).setJar(FRAX_DAI_POOL, pickleJar.address);
    await controller.connect(governance).approveStrategy(FRAX_DAI_POOL, strategy.address);
    await controller.connect(governance).setStrategy(FRAX_DAI_POOL, strategy.address);

    veFxsVault = await deployContract("veFXSVault");
    console.log("✅ veFxsVault is deployed at ", veFxsVault.address);

    await veFxsVault.setProxy(strategyProxy.address);
    await veFxsVault.setFeeDistribution(strategyProxy.address);
    await veFxsVault.setLocker(locker.address);

    await strategyProxy.setFXSVault(veFxsVault.address);

    fxs = await getContractAt("ERC20", FXSToken);

    await getWantFromWhale(FXSToken, toWei(400000), alice, "0x1e84614543ab707089cebb022122503462ac51b3");

    fraxDeployer = await unlockAccount("0x234D953a9404Bf9DbC3b526271d440cD2870bCd2");
    smartChecker = await getContractAt("ISmartWalletChecker", SMARTCHECKER);
  });
  it("should lock to vault correctly", async () => {
    await smartChecker.connect(fraxDeployer).approveWallet(locker.address);
    await fxs.connect(alice).transfer(locker.address, toWei(100000));

    const now = Math.round(new Date().getTime() / 1000);
    const MAXTIME = 60 * 60 * 24 * 360 * 2;

    // Initially lock for 2 years
    await locker.connect(governance).createLock(toWei(100000), now + MAXTIME);
    let locked_end = await escrow.locked__end(locker.address);
    console.log("locked_end => ", locked_end.toString());

    // Increase lock time by 6 months
    await locker.execute(
      "0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0",
      0,
      "0xeff7a6120000000000000000000000000000000000000000000000000000000063372264"
    );
    locked_end = await escrow.locked__end(locker.address);
    console.log("locked_end => ", locked_end.toString());

    // Make a deposit into veFXSVault
    await fxs.connect(alice).approve(veFxsVault.address, toWei(100000));
    await veFxsVault.connect(alice).deposit(toWei(100000));

    await fxs.connect(alice).transfer(FXS_DISTRIBUTOR, toWei(100000));
    const fxsBefore = await fxs.balanceOf(alice.address);
    console.log("FXS balance before claim: ", fxsBefore.toString());

    await increaseTime(60 * 60 * 24 * 30); //travel 30 days
    await increaseBlock(1100);

    await veFxsVault.connect(alice).claim();
    await veFxsVault.connect(alice).claim();

    const fxsAfter = await fxs.balanceOf(alice.address);
    console.log("FXS balance after claim: ", fxsAfter.toString());
    expect(fxsAfter.gt(fxsBefore));
  });
});
