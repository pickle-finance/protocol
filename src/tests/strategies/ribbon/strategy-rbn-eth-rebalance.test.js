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

describe("StrategyRbnEthUniV3Rebalance", () => {
  const RBN_ETH_POOL = "0x94981F69F7483AF3ae218CbfE65233cC3c60d93a";
  const RBN_TOKEN = "0x6123B0049F904d730dB3C36a31167D9d4121fA6B";
  const WETH_TOKEN = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const UNIV3ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";

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
      "ControllerV7",
      governance.address,
      strategist.address,
      timelock.address,
      devfund.address,
      treasury.address
    );

    console.log("✅ Controller is deployed at ", controller.address);

    strategy = await deployContract(
      "StrategyRbnEthUniV3",
      100,
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
    univ3router = await getContractAt("ISwapRouter", UNIV3ROUTER);

    await getWantFromWhale(
      RBN_TOKEN,
      toWei(110000),
      alice,
      "0x65B1B96bD01926d3d60DD3c8bc452F22819443A9"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(5000),
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
      toWei(80),
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

  it("should rebalance correctly", async () => {
    depositA = toWei(100000);
    depositB = await getAmountB(depositA);
    let aliceShare, bobShare, charlesShare;

    console.log("=============== Alice deposit ==============");
    await deposit(alice, depositA, depositB);

    await rebalance();

    console.log("=============== Bob deposit ==============");


    await deposit(bob, depositA, depositB);
    await simulateTrading();
    await deposit(charles, depositA, depositB);
    await harvest();

    aliceShare = await pickleJar.balanceOf(alice.address);
    console.log("Alice share amount => ", aliceShare.toString());

    bobShare = await pickleJar.balanceOf(bob.address);
    console.log("Bob share amount => ", bobShare.toString());

    charlesShare = await pickleJar.balanceOf(charles.address);
    console.log("Charles share amount => ", charlesShare.toString());

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
    await trade(WETH_TOKEN, RBN_TOKEN);
    await rebalance();
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
      "Alice rbn balance before withdrawal => ",harvest
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
    console.log("Harvestable => ", (await strategy.getHarvestable()).toString());
    await increaseTime(13); //travel 1 block
    await increaseBlock(1);
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

  const trade = async (_inputToken, _outputToken) => {
    let input = await getContractAt("ERC20", _inputToken);
    let poolFee = await pool.fee();
    let aliceAddress = alice.address;
    let amount = input.balanceOf(alice.address);
    await input.connect(alice).approve(univ3router.address, amount);
    await univ3router.connect(alice).exactInputSingle({tokenIn: _inputToken, tokenOut: _outputToken, fee: poolFee, recipient: aliceAddress, deadline: "1659935160", amountIn: amount,amountOutMinimum: 0, sqrtPriceLimitX96: 0});
  }

  const simulateTrading = async () => {
    for (let i = 0; i < 100; i++) {
      await trade(WETH_TOKEN, RBN_TOKEN);
      await trade(RBN_TOKEN, WETH_TOKEN);
    }
  }


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
