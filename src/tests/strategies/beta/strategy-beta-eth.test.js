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

describe("StrategyBetaEthUniV3", () => {
  const BETA_ETH_POOL = "0x6BeE0F0DEA573EC04A77Ff3547691f2EDCCf2A7c";
  const BETA_TOKEN = "0xBe1a001FE942f96Eea22bA08783140B9Dcc09D28";
  const WETH_TOKEN = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  let alice;
  let beta, weth;
  let strategy, pickleJar, controller;
  let governance, strategist, timelock, devfund, treasury;

  before("Setup Contracts", async () => {
    [alice, bob, charles, fred] = await hre.ethers.getSigners();
    governance = alice;
    strategist = alice;
    timelock = alice;
    devfund = alice;
    treasury = fred;

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
      "StrategyBetaEthUniV3",
      governance.address,
      strategist.address,
      controller.address,
      timelock.address
    );

    pickleJar = await deployContract(
      "PickleJarUniV3",
      "pickling BETA/ETH Jar",
      "pBETAETH",
      BETA_ETH_POOL,
      -887200,
      887200,
      governance.address,
      timelock.address,
      controller.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await controller.connect(governance).setJar(BETA_ETH_POOL, pickleJar.address);
    await controller.connect(governance).approveStrategy(BETA_ETH_POOL, strategy.address);
    await controller.connect(governance).setStrategy(BETA_ETH_POOL, strategy.address);

    beta = await getContractAt("ERC20", BETA_TOKEN);
    weth = await getContractAt("ERC20", WETH_TOKEN);
    const betaWhale = "0x28C6c06298d514Db089934071355E5743bf21d60"
    const wethWhale = "0xF977814e90dA44bFA03b6295A0616a897441aceC" 

    await getWantFromWhale(
      BETA_TOKEN,
      toWei(11000),
      alice,
      betaWhale
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(80),
      alice,
      wethWhale
    );

    await getWantFromWhale(
      BETA_TOKEN,
      toWei(10000),
      bob,
      betaWhale
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(80),
      bob,
      wethWhale
    );

    await getWantFromWhale(
      BETA_TOKEN,
      toWei(10000),
      charles,
      betaWhale
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(30),
      charles,
      wethWhale
    );

    // Initial deposit to create NFT
    const amountBeta = toWei(1);
    const amountWeth = await getAmountB(amountBeta);

    await beta.connect(alice).transfer(strategy.address, amountBeta);
    await weth.connect(alice).transfer(strategy.address, amountWeth);
    await strategy.connect(alice).depositInitial();
  });

  it("should harvest correctly", async () => {
    let depositA = toWei(10000);
    let depositB = toWei(60);
    let aliceShare, bobShare, charlesShare;

    console.log("=============== Alice deposit ==============");
    console.log("Alice ETH balance before deposit: ", (await alice.getBalance()).toString())
    console.log(
      "Alice weth balance before => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await depositWithEth(alice, depositA, depositB);
    console.log("Alice ETH balance after deposit: ", (await alice.getBalance()).toString())
    await harvest();

    console.log("=============== Bob deposit ==============");
    depositA = toWei(5000);
    depositB = await getAmountB(depositA);

    await deposit(bob, depositA, depositB);
    await harvest();

    aliceShare = await pickleJar.balanceOf(alice.address);
    console.log("Alice share amount => ", aliceShare.toString());

    console.log("===============Alice partial withdraw==============");
    console.log(
      "Alice beta balance before withdrawal => ",
      (await beta.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance before withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

    console.log(
      "Alice beta balance after withdrawal => ",
      (await beta.balanceOf(alice.address)).toString()
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

    depositA = toWei(3000);
    depositB = await getAmountB(depositA);

    await deposit(charles, depositA, depositB);

    console.log("===============Bob withdraw==============");
    console.log(
      "Bob beta balance before withdrawal => ",
      (await beta.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob weth balance before withdrawal => ",
      (await weth.balanceOf(bob.address)).toString()
    );
    await pickleJar.connect(bob).withdrawAll();

    console.log(
      "Bob beta balance after withdrawal => ",
      (await beta.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob weth balance after withdrawal => ",
      (await weth.balanceOf(bob.address)).toString()
    );

    await harvest();

    console.log("=============== Controller withdraw ===============");
    console.log(
      "PickleJar beta balance before withdrawal => ",
      (await beta.balanceOf(pickleJar.address)).toString()
    );
    console.log(
      "PickleJar weth balance before withdrawal => ",
      (await weth.balanceOf(pickleJar.address)).toString()
    );

    await controller.withdrawAll(BETA_ETH_POOL);

    console.log(
      "PickleJar beta balance after withdrawal => ",
      (await beta.balanceOf(pickleJar.address)).toString()
    );
    console.log(
      "PickleJar weth balance after withdrawal => ",
      (await weth.balanceOf(pickleJar.address)).toString()
    );

    console.log("===============Alice Full withdraw==============");

    console.log(
      "Alice beta balance before withdrawal => ",
      (await beta.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance before withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdrawAll();

    console.log(
      "Alice beta balance after withdrawal => ",
      (await beta.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance after withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );

    console.log("=============== charles withdraw ==============");
    console.log(
      "Charles beta balance before withdrawal => ",
      (await beta.balanceOf(charles.address)).toString()
    );
    console.log(
      "Charles weth balance before withdrawal => ",
      (await weth.balanceOf(charles.address)).toString()
    );
    await pickleJar.connect(charles).withdrawAll();

    console.log(
      "Charles beta balance after withdrawal => ",
      (await beta.balanceOf(charles.address)).toString()
    );
    console.log(
      "Charles weth balance after withdrawal => ",
      (await weth.balanceOf(charles.address)).toString()
    );

    console.log("------------------ Finished -----------------------");

    console.log("Treasury beta balance => ", (await beta.balanceOf(treasury.address)).toString());
    console.log("Treasury weth balance => ", (await weth.balanceOf(treasury.address)).toString());

    console.log("Strategy beta balance => ", (await beta.balanceOf(strategy.address)).toString());
    console.log("Strategy weth balance => ", (await weth.balanceOf(strategy.address)).toString());
    console.log("PickleJar beta balance => ", (await beta.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar weth balance => ", (await weth.balanceOf(pickleJar.address)).toString());
  });

  const deposit = async (user, depositA, depositB) => {
    await beta.connect(user).approve(pickleJar.address, depositA);
    await weth.connect(user).approve(pickleJar.address, depositB);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, depositB);
  };

  const depositWithEth = async (user, depositA, depositB) => {
    await beta.connect(user).approve(pickleJar.address, depositA);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, 0, {value: depositB});
  };


  const harvest = async () => {
    console.log("============ Harvest Started ==============");

    console.log("Ratio before harvest => ", (await pickleJar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 5); //travel 5 days
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
