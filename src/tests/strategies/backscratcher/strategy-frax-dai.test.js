const {
  toWei,
  deployContract,
  getContractAt,
  increaseTime,
  increaseBlock,
  unlockAccount,
} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");

describe("StrategyFraxDAI", () => {
  const FRAX_DAI_POOL = "0x97e7d56A0408570bA1a7852De36350f7713906ec";
  const FRAX_DAI_GAUGE = "0xF22471AC2156B489CC4a59092c56713F813ff53e";
  const FraxToken = "0x853d955acef822db058eb8505911ed77f175b99e";
  const DAIToken = "0x6b175474e89094c44da98b954eedeac495271d0f";

  let alice;
  let frax, dai;
  let strategy, pickleJar, controller, proxyAdmin, strategyProxy, locker;
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

    strategyProxy = await deployContract("StrategyProxy");
    console.log("✅ StrategyProxy is deployed at ", strategyProxy.address);

    locker = await deployContract("FXSLocker");
    await locker.setStrategy(strategyProxy.address);

    await strategyProxy.setLockerProxy(locker.address);

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
      "PickleJarV2",
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

    frax = await getContractAt("ERC20", FraxToken);
    dai = await getContractAt("ERC20", DAIToken);

    await getWantFromWhale(
      FraxToken,
      toWei(1000000),
      alice,
      "0x820A9eb227BF770A9dd28829380d53B76eAf1209"
    );

    await getWantFromWhale(
      DAIToken,
      toWei(1000000),
      alice,
      "0xB60C61DBb7456f024f9338c739B02Be68e3F545C"
    );

    await getWantFromWhale(
      FraxToken,
      toWei(1000000),
      bob,
      "0x820A9eb227BF770A9dd28829380d53B76eAf1209"
    );

    await getWantFromWhale(
      DAIToken,
      toWei(1000000),
      bob,
      "0xB60C61DBb7456f024f9338c739B02Be68e3F545C"
    );
  });

  it("should harvest correctly", async () => {
    let depositA = toWei(100000);
    let depositB = getAmountB(depositA);

    // await dai.connect(alice).approve(pickleJar.address, depositA);
    // await frax.connect(alice).approve(pickleJar.address, depositB);

    // console.log("===============alice deposit==============");
    // await pickleJar.connect(alice).deposit(depositA, depositB);
    // await pickleJar.earn();

    // console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    // await increaseTime(60 * 60 * 24 * 30); //travel 30 days
    // await strategy.harvest();
    // console.log("Ratio after harvest => ", (await pickleJar.getRatio()).toString());

    depositA = toWei(400000);
    depositB = getAmountB(depositA);

    await dai.connect(bob).approve(pickleJar.address, depositA);
    await frax.connect(bob).approve(pickleJar.address, depositB);

    console.log("===============bob deposit==============");
    await pickleJar.connect(bob).deposit(depositA, depositB);
    await pickleJar.earn();

    console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 24); //travel 24 days
    await strategy.harvest();
    console.log("Ratio after harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 14); //travel 14 days

    console.log("===============Alice withdraw==============");
    console.log(
      "Alice dai balance before withdrawal => ",
      (await dai.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice frax balance before withdrawal => ",
      (await frax.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdrawAll();

    console.log(
      "Alice dai balance before withdrawal => ",
      (await dai.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice frax balance before withdrawal => ",
      (await frax.balanceOf(alice.address)).toString()
    );

    console.log("===============Bob withdraw==============");
    console.log(
      "Bob dai balance before withdrawal => ",
      (await dai.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob frax balance before withdrawal => ",
      (await frax.balanceOf(bob.address)).toString()
    );
    await pickleJar.connect(bob).withdrawAll();

    console.log(
      "Bob dai balance before withdrawal => ",
      (await dai.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob frax balance before withdrawal => ",
      (await frax.balanceOf(bob.address)).toString()
    );

    console.log("Treasury dai balance => ", (await dai.balanceOf(treasury.address)).toString());
    console.log("Treasury frax balance => ", (await frax.balanceOf(treasury.address)).toString());
  });

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
