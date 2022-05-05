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

describe("StrategyFraxUSDC", () => {
  const FRAX_USDC_POOL = "0xc63B0708E2F7e69CB8A1df0e1389A98C35A76D52";
  const FRAX_USDC_GAUGE = "0x3EF26504dbc8Dd7B7aa3E97Bc9f3813a9FC0B4B0";
  const FraxToken = "0x853d955acef822db058eb8505911ed77f175b99e";
  const USDCToken = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const FXSToken = "0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0";
  const SMARTCHECKER = "0x53c13BA8834a1567474b19822aAD85c6F90D9f9F";

  let alice;
  let frax, usdc, fxs, fraxDeployer, escrow;
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
      "StrategyFraxUsdcUniV3",
      governance.address,
      strategist.address,
      newController.address,
      timelock.address
    );
    await strategy.connect(governance).setStrategyProxy(strategyProxy.address);
    await strategyProxy.approveStrategy(FRAX_USDC_GAUGE, strategy.address);

    pickleJar = await deployContract(
      "PickleJarStablesUniV3",
      "pickling Frax/USDC Jar",
      "pFraxUSDC",
      FRAX_USDC_POOL,
      governance.address,
      timelock.address,
      newController.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await newController.connect(governance).setJar(FRAX_USDC_POOL, pickleJar.address);
    await newController.connect(governance).approveStrategy(FRAX_USDC_POOL, strategy.address);
    await newController.connect(governance).setStrategy(FRAX_USDC_POOL, strategy.address);

    veFxsVault = await deployContract("veFXSVault");
    console.log("✅ veFxsVault is deployed at ", veFxsVault.address);

    await veFxsVault.setProxy(strategyProxy.address);
    await veFxsVault.setFeeDistribution(strategyProxy.address);
    await veFxsVault.setLocker(locker.address);

    await strategyProxy.setFXSVault(veFxsVault.address);

    frax = await getContractAt("ERC20", FraxToken);
    usdc = await getContractAt("ERC20", USDCToken);
    fxs = await getContractAt("ERC20", FXSToken);

    await getWantFromWhale(FraxToken, toWei(100000), alice, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");
    await getWantFromWhale(USDCToken, "100000000000000", alice, "0xE78388b4CE79068e89Bf8aA7f218eF6b9AB0e9d0");
    await getWantFromWhale(FraxToken, toWei(100000), bob, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");
    await getWantFromWhale(USDCToken, "100000000000000", bob, "0xE78388b4CE79068e89Bf8aA7f218eF6b9AB0e9d0");
    await getWantFromWhale(FraxToken, toWei(100000), charles, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");
    await getWantFromWhale(USDCToken, "100000000000000", charles, "0xE78388b4CE79068e89Bf8aA7f218eF6b9AB0e9d0");
    await getWantFromWhale(FXSToken, toWei(100000), alice, "0xF977814e90dA44bFA03b6295A0616a897441aceC");

    // transfer FXS to distributor
    fxs.connect(alice).transfer("0x278dc748eda1d8efef1adfb518542612b49fcd34", toWei(10000));
    // transfer FXS to gauge
    fxs.connect(alice).transfer(FRAX_USDC_GAUGE, toWei(10000));
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
    console.log("Alice usdc balance before withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

    console.log("Alice usdc balance after withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== Charles deposit ==============");

    depositA = toWei(70000);
    depositB = await getAmountB(depositA);

    await deposit(charles, depositA, depositB);

    console.log("===============Bob withdraw==============");
    console.log("Bob usdc balance before withdrawal => ", (await usdc.balanceOf(bob.address)).toString());
    console.log("Bob frax balance before withdrawal => ", (await frax.balanceOf(bob.address)).toString());
    await pickleJar.connect(bob).withdrawAll();

    console.log("Bob usdc balance after withdrawal => ", (await usdc.balanceOf(bob.address)).toString());
    console.log("Bob frax balance after withdrawal => ", (await frax.balanceOf(bob.address)).toString());

    await harvest();
    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    await pickleJar.earn();

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== Controller withdraw ===============");
    console.log("PickleJar usdc balance before withdrawal => ", (await usdc.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance before withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    await controller.withdrawAll(FRAX_USDC_POOL);

    console.log("PickleJar usdc balance after withdrawal => ", (await usdc.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance after withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    console.log("===============Alice Full withdraw==============");

    console.log("Alice usdc balance before withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    await pickleJar.connect(alice).withdrawAll();

    console.log("Alice usdc balance after withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    // await harvest();
    // await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== charles withdraw ==============");
    console.log("Charles usdc balance before withdrawal => ", (await usdc.balanceOf(charles.address)).toString());
    console.log("Charles frax balance before withdrawal => ", (await frax.balanceOf(charles.address)).toString());
    await pickleJar.connect(charles).withdrawAll();

    console.log("Charles usdc balance after withdrawal => ", (await usdc.balanceOf(charles.address)).toString());
    console.log("Charles frax balance after withdrawal => ", (await frax.balanceOf(charles.address)).toString());

    // console.log("=============== Alice redeposit ==============");
    // depositA = toWei(50000);
    // depositB = await getAmountB(depositA);

    // await deposit(alice, depositA, depositB);
    // await pickleJar.earn();

    // await harvest();
    // await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    // console.log("===============Alice final withdraw==============");

    // console.log("Alice usdc balance before withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    // console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    // await pickleJar.connect(alice).withdrawAll();

    // console.log("Alice usdc balance after withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    // console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    console.log("------------------ Finished -----------------------");

    console.log("Treasury usdc balance => ", (await usdc.balanceOf(treasury.address)).toString());
    console.log("Treasury frax balance => ", (await frax.balanceOf(treasury.address)).toString());

    console.log("Strategy usdc balance => ", (await usdc.balanceOf(strategy.address)).toString());
    console.log("Strategy frax balance => ", (await frax.balanceOf(strategy.address)).toString());
    console.log("Strategy fxs balance => ", (await fxs.balanceOf(strategy.address)).toString());

    console.log("PickleJar usdc balance => ", (await usdc.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance => ", (await frax.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar fxs balance => ", (await fxs.balanceOf(pickleJar.address)).toString());

    console.log("Locker usdc balance => ", (await usdc.balanceOf(locker.address)).toString());
    console.log("Locker frax balance => ", (await frax.balanceOf(locker.address)).toString());
    console.log("Locker fxs balance => ", (await fxs.balanceOf(locker.address)).toString());

    console.log("StrategyProxy usdc balance => ", (await usdc.balanceOf(strategyProxy.address)).toString());
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
    console.log("PickleJar usdc balance before withdrawal => ", (await usdc.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance before withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    await controller.withdrawAll(FRAX_usdc_POOL);

    console.log("PickleJar usdc balance after withdrawal => ", (await usdc.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance after withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    console.log("Alice usdc balance before withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    await pickleJar.connect(alice).withdrawAll();

    console.log("Alice usdc balance after withdrawal => ", (await usdc.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());
  });
*/
  const deposit = async (user, depositA, depositB) => {
    await usdc.connect(user).approve(pickleJar.address, "999999999999999999999999999999999999");
    await frax.connect(user).approve(pickleJar.address, "999999999999999999999999999999999999");
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, depositB);
  };

  const harvest = async () => {
    console.log("============ Harvest Started ==============");

    console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 14); //travel 30 days
    await increaseBlock(1000);
    console.log("Amount Harvestable => ", (await strategy.getHarvestable()).toString());
    await strategy.harvest();
    console.log("Amount Harvestable after => ", (await strategy.getHarvestable()).toString());
    console.log("Ratio after harvest => ", (await pickleJar.getRatio()).toString());
    console.log("============ Harvest Ended ==============");
  };

  const getAmountB = async (amountA) => {
    const proportion = await pickleJar.getProportion();
    console.log("Proportion: ", proportion.toString());
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
