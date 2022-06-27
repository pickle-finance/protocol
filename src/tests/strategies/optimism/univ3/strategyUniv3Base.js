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

const doUniV3TestBehaviorBase = (
  strategyName,
  token0Name,
  token0Address,
  token1Name,
  token1Address,
  token0Whale,
  token1Whale,
  poolAddr,
  chain = "mainnet", // mainnet, polygon or optimism
  depositNative = false,
  depositNativeTokenIs1 = false,
) => {
  describe(`${strategyName}`, () => {
    let alice;
    let token0, token1;
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

      console.log("✅ Controller is deployed at ", controller.address);

      strategy = await deployContract(
        `${strategyName}`,
        100,
        governance.address,
        strategist.address,
        controller.address,
        timelock.address
      );

      console.log("✅ Strategy is deployed at ", strategy.address);
      // console.log("✅ Strategy Swap Fee: ", await strategy.swapPoolFee());
      let jarContract =
        chain === "mainnet"
          ? "src/pickle-jar-univ3.sol:PickleJarUniV3"
          : chain === "polygon"
          ? "src/polygon/pickle-jar-univ3.sol:PickleJarUniV3Poly"
          : "src/optimism/pickle-jar-univ3.sol:PickleJarUniV3Optimism";

      let jarDescrip = `pickling ${token0Name}/${token1Name} Jar`;
      let pTokenName = `p${token0Name}${token1Name}`;

      pickleJar = await deployContract(
        jarContract,
        jarDescrip,
        pTokenName,
        poolAddr,
        governance.address,
        timelock.address,
        controller.address
      );
      console.log("✅ PickleJar is deployed at ", pickleJar.address);

      await controller.connect(governance).setJar(poolAddr, pickleJar.address);
      await controller.connect(governance).approveStrategy(poolAddr, strategy.address);
      await controller.connect(governance).setStrategy(poolAddr, strategy.address);

      token0 = await getContractAt("ERC20", token0Address);
      token1 = await getContractAt("ERC20", token1Address);

      // univ3router = await getContractAt("src/polygon/interfaces/univ3/ISwapRouter.sol:ISwapRouter", UNIV3ROUTER);

      console.log("✅ Jar Setup Complete ");

      await getWantFromWhale(token0Address, "10000000000", alice, token0Whale);

      await getWantFromWhale(token1Address, "10000000000", alice, token1Whale);

      await getWantFromWhale(token0Address, "10000000000", bob, token0Whale);

      await getWantFromWhale(token1Address, "10000000000", bob, token1Whale);

      await getWantFromWhale(token0Address, "10000000000", charles, token0Whale);

      await getWantFromWhale(token1Address, "10000000000", charles, token1Whale);
      // Initial deposit to create NFT
      const amountToken1 = "100000000";
      const amountToken0 = "10000";

      await token0.connect(alice).transfer(strategy.address, amountToken0);
      await token1.connect(alice).transfer(strategy.address, amountToken1);
      await strategy.rebalance();
    });

    it("should rebalance correctly", async () => {
      depositA = "9000000000"; //await token0.balanceOf(alice.address);
      depositB = "9000000000";
      let aliceShare, bobShare, charlesShare;

      console.log("=============== Alice deposit ==============");

      if (depositNative) {
        depositNativeTokenIs1
          ? await depositWithEthToken1(alice, depositA, depositB)
          : await depositWithEthToken0(alice, depositA, depositB);
      } else {
        await deposit(alice, depositA, depositB);
      }

      await strategy.setTickRangeMultiplier("50");
      await rebalance();

      console.log("=============== Bob deposit ==============");

      await deposit(bob, depositA, depositB);
      //await simulateTrading();
      await deposit(charles, depositA, depositB);
      // await harvest();

      aliceShare = await pickleJar.balanceOf(alice.address);
      console.log("Alice share amount => ", aliceShare.toString());

      bobShare = await pickleJar.balanceOf(bob.address);
      console.log("Bob share amount => ", bobShare.toString());

      charlesShare = await pickleJar.balanceOf(charles.address);
      console.log("Charles share amount => ", charlesShare.toString());

      console.log("===============Alice partial withdraw==============");
      console.log("Alice token0 balance before withdrawal => ", (await token0.balanceOf(alice.address)).toString());
      console.log("Alice token1 balance before withdrawal => ", (await token1.balanceOf(alice.address)).toString());
      await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

      console.log("Alice token0 balance after withdrawal => ", (await token0.balanceOf(alice.address)).toString());
      console.log("Alice token1 balance after withdrawal => ", (await token1.balanceOf(alice.address)).toString());

      console.log("Alice shares remaining => ", (await pickleJar.balanceOf(alice.address)).toString());

      await increaseTime(60 * 60 * 24 * 1); //travel 1 day

      console.log("===============Bob withdraw==============");
      console.log("Bob token0 balance before withdrawal => ", (await token0.balanceOf(bob.address)).toString());
      console.log("Bob token1 balance before withdrawal => ", (await token1.balanceOf(bob.address)).toString());
      await pickleJar.connect(bob).withdrawAll();

      console.log("Bob token0 balance after withdrawal => ", (await token0.balanceOf(bob.address)).toString());
      console.log("Bob token1 balance after withdrawal => ", (await token1.balanceOf(bob.address)).toString());

      //await harvest();

      await rebalance();
      console.log("=============== Controller withdraw ===============");
      console.log(
        "PickleJar token0 balance before withdrawal => ",
        (await token0.balanceOf(pickleJar.address)).toString()
      );
      console.log(
        "PickleJar token1 balance before withdrawal => ",
        (await token1.balanceOf(pickleJar.address)).toString()
      );

      await controller.withdrawAll(poolAddr);

      console.log(
        "PickleJar token0 balance after withdrawal => ",
        (await token0.balanceOf(pickleJar.address)).toString()
      );
      console.log(
        "PickleJar token1 balance after withdrawal => ",
        (await token1.balanceOf(pickleJar.address)).toString()
      );

      console.log("===============Alice Full withdraw==============");

      console.log(
        "Alice token0 balance before withdrawal => ",
        harvest(await token0.balanceOf(alice.address)).toString()
      );
      console.log("Alice token1 balance before withdrawal => ", (await token1.balanceOf(alice.address)).toString());
      await pickleJar.connect(alice).withdrawAll();

      console.log("Alice token0 balance after withdrawal => ", (await token0.balanceOf(alice.address)).toString());
      console.log("Alice token1 balance after withdrawal => ", (await token1.balanceOf(alice.address)).toString());

      console.log("=============== charles withdraw ==============");
      console.log("Charles token0 balance before withdrawal => ", (await token0.balanceOf(charles.address)).toString());
      console.log("Charles token1 balance before withdrawal => ", (await token1.balanceOf(charles.address)).toString());
      await pickleJar.connect(charles).withdrawAll();

      console.log("Charles token0 balance after withdrawal => ", (await token0.balanceOf(charles.address)).toString());
      console.log("Charles token1 balance after withdrawal => ", (await token1.balanceOf(charles.address)).toString());

      console.log("------------------ Finished -----------------------");

      console.log("Treasury token0 balance => ", (await token0.balanceOf(treasury.address)).toString());
      console.log("Treasury token1 balance => ", (await token1.balanceOf(treasury.address)).toString());

      console.log("Strategy token0 balance => ", (await token0.balanceOf(strategy.address)).toString());
      console.log("Strategy token1 balance => ", (await token1.balanceOf(strategy.address)).toString());
      console.log("PickleJar token0 balance => ", (await token0.balanceOf(pickleJar.address)).toString());
      console.log("PickleJar token1 balance => ", (await token1.balanceOf(pickleJar.address)).toString());
    });

    const deposit = async (user, depositA, depositB) => {
      if (depositA != "0") await token0.connect(user).approve(pickleJar.address, depositA);
      if (depositB != "0") await token1.connect(user).approve(pickleJar.address, depositB);
      console.log("depositA => ", depositA.toString());
      console.log("depositB => ", depositB.toString());
      console.log("Strategy token0 Before Deposit: ", (await token0.balanceOf(strategy.address)).toString());
      console.log("Strategy token1 Before Deposit: ", (await token1.balanceOf(strategy.address)).toString());

      await pickleJar.connect(user).deposit(depositA, depositB);

      console.log("Strategy token0 After Deposit: ", (await token0.balanceOf(strategy.address)).toString());
      console.log("Strategy token1 After Deposit: ", (await token1.balanceOf(strategy.address)).toString());
    };

    const depositWithEthToken1 = async (user, depositA, depositB) => {
      await token0.connect(user).approve(pickleJar.address, depositA);
      console.log("depositA => ", depositA.toString());
      console.log("depositB => ", depositB.toString());
      console.log("User Balance before => ", (await hre.network.provider.getBalance(user)).toString());
      await pickleJar.connect(user).deposit(depositA, 0, {value: depositB});
      console.log("User Balance after => ", (await hre.network.provider.getBalance(user)).toString());

      console.log("");
    };

    const depositWithEthToken0 = async (user, depositA, depositB) => {
      await token1.connect(user).approve(pickleJar.address, depositB);
      console.log("depositA => ", depositA.toString());
      console.log("depositB => ", depositB.toString());
      console.log("User Balance before => ", (await ethers.provider.getBalance(user.address)).toString());
      await pickleJar.connect(user).deposit(0, depositB, {value: depositA});
      console.log("User Balance after => ", (await ethers.provider.getBalance(user.address)).toString());
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
      console.log("Strategy token0 Before Rebalance: ", (await token0.balanceOf(strategy.address)).toString());
      console.log("Strategy token1 Before Rebalance: ", (await token1.balanceOf(strategy.address)).toString());
      await strategy.rebalance();
      console.log("Ratio after rebalance => ", (await pickleJar.getRatio()).toString());
      console.log("TickLower after rebalance => ", (await pickleJar.getLowerTick()).toString());
      console.log("TickUpper after rebalance => ", (await pickleJar.getUpperTick()).toString());
      console.log("Strategy token0 After Rebalance: ", (await token0.balanceOf(strategy.address)).toString());
      console.log("Strategy token1 After Rebalance: ", (await token1.balanceOf(strategy.address)).toString());
      console.log("============ Rebalance Ended ==============");
    };
  });
};
module.exports = {doUniV3TestBehaviorBase};
