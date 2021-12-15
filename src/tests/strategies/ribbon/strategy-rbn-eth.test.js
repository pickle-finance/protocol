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

describe("StrategyRbnEthUniV3", () => {
  const RBN_ETH_POOL = "0x94981F69F7483AF3ae218CbfE65233cC3c60d93a";
  const RBN_TOKEN = "0x6123B0049F904d730dB3C36a31167D9d4121fA6B";
  const WETH_TOKEN = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  let alice;
  let rbn, weth;
  let strategy, pickleJar, controller;
  let governance, strategist, timelock, devfund, treasury;

  before("Setup Contracts", async () => {
    [alice, bob, charles, fred] = await hre.ethers.getSigners();
    governance = alice;
    strategist = alice;
    timelock = alice;
    devfund = alice;
    treasury = fred;

    proxyAdmin = await deployContract("ProxyAdmin");
    console.log("✅ ProxyAdmin is deployed at ", proxyAdmin.address);

    controller = await deployContract(
      "ControllerV6",
      governance.address,
      strategist.address,
      timelock.address,
      devfund.address,
      treasury.address
    );

    console.log("✅ Controller is deployed at ", controller.address);

    strategy = await deployContract(
      "StrategyRbnEthUniV3",
      governance.address,
      strategist.address,
      controller.address,
      timelock.address
    );

    pickleJar = await deployContract(
      "PickleJarUniV3",
      "pickling RBN/ETH Jar",
      "pRBNETH",
      RBN_ETH_POOL,
      -887200,
      887200,
      governance.address,
      timelock.address,
      controller.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await controller.connect(governance).setJar(RBN_ETH_POOL, pickleJar.address);
    await controller.connect(governance).approveStrategy(RBN_ETH_POOL, strategy.address);
    await controller.connect(governance).setStrategy(RBN_ETH_POOL, strategy.address);

    rbn = await getContractAt("ERC20", RBN_TOKEN);
    weth = await getContractAt("ERC20", WETH_TOKEN);
    pool = await getContractAt("IUniswapV3Pool", RBN_ETH_POOL);

    await getWantFromWhale(
      RBN_TOKEN,
      toWei(110000),
      alice,
      "0x65B1B96bD01926d3d60DD3c8bc452F22819443A9"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(80),
      alice,
      "0x57757E3D981446D585Af0D9Ae4d7DF6D64647806"
    );

    await getWantFromWhale(
      RBN_TOKEN,
      toWei(100000),
      bob,
      "0x65B1B96bD01926d3d60DD3c8bc452F22819443A9"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(80),
      bob,
      "0x57757E3D981446D585Af0D9Ae4d7DF6D64647806"
    );

    await getWantFromWhale(
      RBN_TOKEN,
      toWei(100000),
      charles,
      "0x65B1B96bD01926d3d60DD3c8bc452F22819443A9"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(30),
      charles,
      "0x57757E3D981446D585Af0D9Ae4d7DF6D64647806"
    );

    // Initial deposit to create NFT
    const amountRbn = toWei(1);
    const amountWeth = await getAmountB(amountRbn);

    await rbn.connect(alice).transfer(strategy.address, amountRbn);
    await weth.connect(alice).transfer(strategy.address, amountWeth);
    await strategy.connect(alice).depositInitial();
  });

  it("should harvest correctly", async () => {
    let depositA = toWei(10000);
    let depositB = toWei(60);
    let aliceShare, bobShare, charlesShare;

    console.log("=============== Alice deposit ==============");
    console.log("Alice ETH balance before deposit: ", (await alice.getBalance()).toString());
    console.log("Alice weth balance before => ", (await weth.balanceOf(alice.address)).toString());
    await depositWithEth(alice, depositA, depositB);
    console.log("Alice ETH balance after deposit: ", (await alice.getBalance()).toString());
    await rebalance();
    await harvest();

    console.log("=============== Bob deposit ==============");
    depositA = toWei(100000);
    depositB = await getAmountB(depositA);

    await deposit(bob, depositA, depositB);
    await harvest();

    aliceShare = await pickleJar.balanceOf(alice.address);
    console.log("Alice share amount => ", aliceShare.toString());

    console.log("===============Alice partial withdraw==============");
    console.log(
      "Alice rbn balance before withdrawal => ",
      (await rbn.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance before withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

    console.log(
      "Alice rbn balance after withdrawal => ",
      (await rbn.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance after withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );

    console.log(
      "Alice shares remaining => ",
      (await pickleJar.balanceOf(alice.address)).toString()
    );

    await increaseTime(60 * 60 * 24 * 1); //travel 1 day

    console.log("=============== Charles deposit ==============");

    depositA = toWei(30000);
    depositB = await getAmountB(depositA);

    await deposit(charles, depositA, depositB);

    console.log("===============Bob withdraw==============");
    console.log(
      "Bob rbn balance before withdrawal => ",
      (await rbn.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob weth balance before withdrawal => ",
      (await weth.balanceOf(bob.address)).toString()
    );
    await pickleJar.connect(bob).withdrawAll();

    console.log(
      "Bob rbn balance after withdrawal => ",
      (await rbn.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob weth balance after withdrawal => ",
      (await weth.balanceOf(bob.address)).toString()
    );

    await harvest();
    await rebalance2();
    console.log("=============== Controller withdraw ===============");
    console.log(
      "PickleJar rbn balance before withdrawal => ",
      (await rbn.balanceOf(pickleJar.address)).toString()
    );
    console.log(
      "PickleJar weth balance before withdrawal => ",
      (await weth.balanceOf(pickleJar.address)).toString()
    );

    await controller.withdrawAll(RBN_ETH_POOL);

    console.log(
      "PickleJar rbn balance after withdrawal => ",
      (await rbn.balanceOf(pickleJar.address)).toString()
    );
    console.log(
      "PickleJar weth balance after withdrawal => ",
      (await weth.balanceOf(pickleJar.address)).toString()
    );

    console.log("===============Alice Full withdraw==============");

    console.log(
      "Alice rbn balance before withdrawal => ",
      (await rbn.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance before withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdrawAll();

    console.log(
      "Alice rbn balance after withdrawal => ",
      (await rbn.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance after withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );

    console.log("=============== charles withdraw ==============");
    console.log(
      "Charles rbn balance before withdrawal => ",
      (await rbn.balanceOf(charles.address)).toString()
    );
    console.log(
      "Charles weth balance before withdrawal => ",
      (await weth.balanceOf(charles.address)).toString()
    );
    await pickleJar.connect(charles).withdrawAll();

    console.log(
      "Charles rbn balance after withdrawal => ",
      (await rbn.balanceOf(charles.address)).toString()
    );
    console.log(
      "Charles weth balance after withdrawal => ",
      (await weth.balanceOf(charles.address)).toString()
    );

    console.log("------------------ Finished -----------------------");

    console.log("Treasury rbn balance => ", (await rbn.balanceOf(treasury.address)).toString());
    console.log("Treasury weth balance => ", (await weth.balanceOf(treasury.address)).toString());

    console.log("Strategy rbn balance => ", (await rbn.balanceOf(strategy.address)).toString());
    console.log("Strategy weth balance => ", (await weth.balanceOf(strategy.address)).toString());
    console.log("PickleJar rbn balance => ", (await rbn.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar weth balance => ", (await weth.balanceOf(pickleJar.address)).toString());
  });

  const deposit = async (user, depositA, depositB) => {
    await rbn.connect(user).approve(pickleJar.address, depositA);
    await weth.connect(user).approve(pickleJar.address, depositB);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, depositB);
  };

  const depositWithEth = async (user, depositA, depositB) => {
    await rbn.connect(user).approve(pickleJar.address, depositA);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, 0, {value: depositB});
  };

  const harvest = async () => {
    console.log("============ Harvest Started ==============");

    console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 10); //travel 10 days
    await increaseBlock(1000);
    await strategy.harvest();
    console.log("Ratio after harvest => ", (await pickleJar.getRatio()).toString());
    console.log("============ Harvest Ended ==============");
  };

  const rebalance = async () => {
    console.log("============ Rebalance Started ==============");

    console.log("Ratio before rebalance => ", (await pickleJar.getRatio()).toString());
    await strategy.rebalance();
    console.log("Ratio after rebalance => ", (await pickleJar.getRatio()).toString());
    console.log("============ Rebalance Ended ==============");
  };

  const rebalance2 = async () => {
    console.log("============ Rebalance Started ==============");

    console.log("Ratio before rebalance => ", (await pickleJar.getRatio()).toString());
    await strategy.connect(governance).setTickRangeMultiplier(20);
    await strategy.rebalance();
    console.log("Ratio after rebalance => ", (await pickleJar.getRatio()).toString());
    console.log("============ Rebalance Ended ==============");
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
