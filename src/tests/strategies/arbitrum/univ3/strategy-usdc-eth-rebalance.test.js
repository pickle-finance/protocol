const {
  toWei,
  deployContract,
  getContractAt,
  increaseTime,
  increaseBlock,
  unlockAccount,
} = require("../../../utils/testHelper");
const {getWantFromWhale} = require("../../../utils/setupHelper");
const {BigNumber: BN} = require("ethers");

describe("StrategyUsdcEthUniV3Rebalance", () => {
  const USDC_ETH_POOL = "0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443";
  const USDC_TOKEN = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8";
  const WETH_TOKEN = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";
  const UNIV3ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";

  let alice;
  let usdc, weth;
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
      "StrategyUsdcEthUniV3Arbi",
      100,
      governance.address,
      strategist.address,
      controller.address,
      timelock.address
    );

    pickleJar = await deployContract(
      "PickleJarUniV3",
      "pickling USDC/ETH Jar",
      "pUSDCETH",
      USDC_ETH_POOL,
      governance.address,
      timelock.address,
      controller.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    await controller.connect(governance).setJar(USDC_ETH_POOL, pickleJar.address);
    await controller.connect(governance).approveStrategy(USDC_ETH_POOL, strategy.address);
    await controller.connect(governance).setStrategy(USDC_ETH_POOL, strategy.address);

    usdc = await getContractAt("ERC20", USDC_TOKEN);
    weth = await getContractAt("src/interfaces/weth.sol:WETH", WETH_TOKEN);
    pool = await getContractAt("IUniswapV3Pool", USDC_ETH_POOL);
    univ3router = await getContractAt("ISwapRouter", UNIV3ROUTER);

    await weth.deposit({value: toWei(100)});
    await getWantFromWhale(
      USDC_TOKEN,
      12200780243,
      alice,
      "0xCe2CC46682E9C6D5f174aF598fb4931a9c0bE68e"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(50),
      alice,
      "0x50a704293C7aFd32aF21DC2B3a6f42931Cd10c95"
    );

    await getWantFromWhale(
      USDC_TOKEN,
      12200780243,
      bob,
      "0xCe2CC46682E9C6D5f174aF598fb4931a9c0bE68e"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(25),
      bob,
      "0x50a704293C7aFd32aF21DC2B3a6f42931Cd10c95"
    );

    await getWantFromWhale(
      USDC_TOKEN,
      12200780243,
      charles,
      "0xCe2CC46682E9C6D5f174aF598fb4931a9c0bE68e"
    );

    await getWantFromWhale(
      WETH_TOKEN,
      toWei(25),
      charles,
      "0x50a704293C7aFd32aF21DC2B3a6f42931Cd10c95"
    );

    // Initial deposit to create NFT
    const amountWeth = 1000000000000;
    const amountUsdc = 4000;

    await usdc.connect(alice).transfer(strategy.address, amountUsdc);
    await weth.connect(alice).transfer(strategy.address, amountWeth);
    await strategy.connect(alice).rebalance();
  });

  it("should rebalance correctly", async () => {
    depositA = toWei(1);
    depositB = 1000000000;
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
      "Alice usdc balance before withdrawal => ",
      (await usdc.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance before withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

    console.log(
      "Alice usdc balance after withdrawal => ",
      (await usdc.balanceOf(alice.address)).toString()
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
      "Bob usdc balance before withdrawal => ",
      (await usdc.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob weth balance before withdrawal => ",
      (await weth.balanceOf(bob.address)).toString()
    );
    await pickleJar.connect(bob).withdrawAll();

    console.log(
      "Bob usdc balance after withdrawal => ",
      (await usdc.balanceOf(bob.address)).toString()
    );
    console.log(
      "Bob weth balance after withdrawal => ",
      (await weth.balanceOf(bob.address)).toString()
    );

    await harvest();
    await trade(WETH_TOKEN, USDC_TOKEN);
    await rebalance();
    console.log("=============== Controller withdraw ===============");
    console.log(
      "PickleJar usdc balance before withdrawal => ",
      (await usdc.balanceOf(pickleJar.address)).toString()
    );
    console.log(
      "PickleJar weth balance before withdrawal => ",
      (await weth.balanceOf(pickleJar.address)).toString()
    );

    await controller.withdrawAll(USDC_ETH_POOL);

    console.log(
      "PickleJar usdc balance after withdrawal => ",
      (await usdc.balanceOf(pickleJar.address)).toString()
    );
    console.log(
      "PickleJar weth balance after withdrawal => ",
      (await weth.balanceOf(pickleJar.address)).toString()
    );

    console.log("===============Alice Full withdraw==============");

    console.log(
      "Alice usdc balance before withdrawal => ",
      harvest(await usdc.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance before withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );
    await pickleJar.connect(alice).withdrawAll();

    console.log(
      "Alice usdc balance after withdrawal => ",
      (await usdc.balanceOf(alice.address)).toString()
    );
    console.log(
      "Alice weth balance after withdrawal => ",
      (await weth.balanceOf(alice.address)).toString()
    );

    console.log("=============== charles withdraw ==============");
    console.log(
      "Charles usdc balance before withdrawal => ",
      (await usdc.balanceOf(charles.address)).toString()
    );
    console.log(
      "Charles weth balance before withdrawal => ",
      (await weth.balanceOf(charles.address)).toString()
    );
    await pickleJar.connect(charles).withdrawAll();

    console.log(
      "Charles usdc balance after withdrawal => ",
      (await usdc.balanceOf(charles.address)).toString()
    );
    console.log(
      "Charles weth balance after withdrawal => ",
      (await weth.balanceOf(charles.address)).toString()
    );

    console.log("------------------ Finished -----------------------");

    console.log("Treasury usdc balance => ", (await usdc.balanceOf(treasury.address)).toString());
    console.log("Treasury weth balance => ", (await weth.balanceOf(treasury.address)).toString());

    console.log("Strategy usdc balance => ", (await usdc.balanceOf(strategy.address)).toString());
    console.log("Strategy weth balance => ", (await weth.balanceOf(strategy.address)).toString());
    console.log("PickleJar usdc balance => ", (await usdc.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar weth balance => ", (await weth.balanceOf(pickleJar.address)).toString());
  });

  const deposit = async (user, depositA, depositB) => {
    await usdc.connect(user).approve(pickleJar.address, depositB);
    await weth.connect(user).approve(pickleJar.address, depositA);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositA, depositB);
  };

  const depositWithEth = async (user, depositA, depositB) => {
    await usdc.connect(user).approve(pickleJar.address, depositB);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await pickleJar.connect(user).deposit(depositB, 0, {value: depositA});
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
    console.log("TickLower before rebalance => ", (await pickleJar.getLowerTick()).toString());
    console.log("TickUpper before rebalance => ", (await pickleJar.getUpperTick()).toString());
    await strategy.rebalance();
    console.log("Ratio after rebalance => ", (await pickleJar.getRatio()).toString());
    console.log("TickLower after rebalance => ", (await pickleJar.getLowerTick()).toString());
    console.log("TickUpper after rebalance => ", (await pickleJar.getUpperTick()).toString());
    console.log("============ Rebalance Ended ==============");
  };

  const trade = async (_inputToken, _outputToken) => {
    let input = await getContractAt("ERC20", _inputToken);
    let poolFee = await pool.fee();
    let aliceAddress = alice.address;
    let amount = input.balanceOf(alice.address);
    await input.connect(alice).approve(univ3router.address, amount);
    await univ3router
      .connect(alice)
      .exactInputSingle({
        tokenIn: _inputToken,
        tokenOut: _outputToken,
        fee: poolFee,
        recipient: aliceAddress,
        deadline: "1659935160",
        amountIn: amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0,
      });
  };

  const simulateTrading = async () => {
    for (let i = 0; i < 100; i++) {
      await trade(WETH_TOKEN, USDC_TOKEN);
      await trade(USDC_TOKEN, WETH_TOKEN);
    }
  };

  const getAmountB = async (amountA) => {
    const proportion = await strategy.getProportion();
    const temp = await strategy.amountsForLiquid();
    const token0 = await strategy.token0();
    const token1 = await strategy.token1();

    const amountB = amountA.mul(proportion).div(hre.ethers.BigNumber.from("1000000000000000000"))
                    .div(hre.ethers.BigNumber.from("1000000000000"));
    return amountB;
  };

  // beforeEach(async () => {
  //   preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
  // });

  // afterEach(async () => {
  //   await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
  // });
});
