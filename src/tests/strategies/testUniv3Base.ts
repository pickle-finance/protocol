import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";
import {
  deployContract,
  increaseTime,
  getContractAt,
  increaseBlock,
} from "../utils/testHelper";
import { getWantFromWhale } from "../utils/setupHelper";
import { BigNumber, Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export interface TokenParams {
  name: string;
  tokenAddr: string;
  whaleAddr: string;
  amount: BigNumber;
}
export const doUniV3TestBehaviorBase = (
  strategyName: string,
  token0Args: TokenParams,
  token1Args: TokenParams,
  poolAddr: string,
  chain = "mainnet", // mainnet, polygon, optimism or arbitrum
  depositNative = false,
  depositNativeTokenIs1 = false
) => {
  describe(`${strategyName}`, () => {
    let alice: SignerWithAddress,
      bob: SignerWithAddress,
      charles: SignerWithAddress,
      fred: SignerWithAddress;
    let token0: Contract, token1: Contract;
    let strategy: Contract,
      pickleJar: Contract,
      controller: Contract,
      router: Contract,
      pool: Contract;
    let governance: SignerWithAddress,
      strategist: SignerWithAddress,
      timelock: SignerWithAddress,
      devfund: SignerWithAddress,
      treasury: SignerWithAddress;

    before("Setup Contracts", async () => {
      [alice, bob, charles, fred] = await ethers.getSigners();
      governance = alice;
      strategist = alice;
      timelock = alice;
      devfund = alice;
      treasury = fred;

      controller = await deployContract(
        "/src/controller-v7.sol:ControllerV7",
        governance.address,
        strategist.address,
        timelock.address,
        devfund.address,
        treasury.address
      );

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
          : chain === "arbitrum"
          ? "src/arbitrum/pickle-jar-univ3.sol:PickleJarUniV3Arbitrum"
          : "src/optimism/pickle-jar-univ3.sol:PickleJarUniV3Optimism";

      let jarDescrip = `pickling ${token0Args.name}/${token1Args.name} Jar`;
      let pTokenName = `p${token0Args.name}${token1Args.name}`;

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
      await controller
        .connect(governance)
        .approveStrategy(poolAddr, strategy.address);
      await controller
        .connect(governance)
        .setStrategy(poolAddr, strategy.address);

      token0 = await getContractAt(
        "src/lib/erc20.sol:ERC20",
        token0Args.tokenAddr
      );
      token1 = await getContractAt(
        "src/lib/erc20.sol:ERC20",
        token1Args.tokenAddr
      );

      router = await getContractAt(
        chain === "mainnet"
          ? "src/interfaces/univ3/ISwapRouter.sol:ISwapRouter"
          : "src/optimism/interfaces/univ3/ISwapRouter.sol:ISwapRouter",
        await strategy.univ3Router()
      );

      pool = await getContractAt(
        "src/interfaces/univ3/IUniswapV3Pool.sol:IUniswapV3Pool",
        poolAddr
      );

      console.log("✅ Jar Setup Complete ");

      const transferAmount0 = token0Args.amount.div(3);
      const transferAmount1 = token1Args.amount.div(3);

      await getWantFromWhale(
        token0Args.tokenAddr,
        transferAmount0,
        alice,
        token0Args.whaleAddr
      );
      await getWantFromWhale(
        token0Args.tokenAddr,
        transferAmount0,
        bob,
        token0Args.whaleAddr
      );
      await getWantFromWhale(
        token0Args.tokenAddr,
        transferAmount0,
        charles,
        token0Args.whaleAddr
      );

      await getWantFromWhale(
        token1Args.tokenAddr,
        transferAmount1,
        alice,
        token1Args.whaleAddr
      );
      await getWantFromWhale(
        token1Args.tokenAddr,
        transferAmount1,
        bob,
        token1Args.whaleAddr
      );
      await getWantFromWhale(
        token1Args.tokenAddr,
        transferAmount1,
        charles,
        token1Args.whaleAddr
      );

      // Initial deposit to create NFT
      const amountToken0 = transferAmount0.div(10);
      const amountToken1 = transferAmount1.div(10);

      await token0.connect(alice).transfer(strategy.address, amountToken0);
      await token1.connect(alice).transfer(strategy.address, amountToken1);
      await strategy.rebalance();
    });
    it("should rebalance correctly", async () => {
      let depositA = await token0.balanceOf(alice.address);
      let depositB = await token1.balanceOf(alice.address);
      let aliceShare: BigNumber, bobShare: BigNumber, charlesShare: BigNumber;

      console.log("=============== Alice deposit ==============");

      if (depositNative) {
        depositNativeTokenIs1
          ? await depositWithEthToken1(alice, depositA, depositB)
          : await depositWithEthToken0(alice, depositA, depositB);
      } else {
        await deposit(alice, depositA.div(2), depositB.div(2));
      }

      await strategy.setTickRangeMultiplier("50");
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
        "Alice token0 balance before withdrawal => ",
        (await token0.balanceOf(alice.address)).toString()
      );
      console.log(
        "Alice token1 balance before withdrawal => ",
        (await token1.balanceOf(alice.address)).toString()
      );
      await pickleJar
        .connect(alice)
        .withdraw(aliceShare.div(BigNumber.from(2)));

      console.log(
        "Alice token0 balance after withdrawal => ",
        (await token0.balanceOf(alice.address)).toString()
      );
      console.log(
        "Alice token1 balance after withdrawal => ",
        (await token1.balanceOf(alice.address)).toString()
      );

      console.log(
        "Alice shares remaining => ",
        (await pickleJar.balanceOf(alice.address)).toString()
      );

      await increaseTime(60 * 60 * 24 * 1); //travel 1 day

      console.log("===============Bob withdraw==============");
      console.log(
        "Bob token0 balance before withdrawal => ",
        (await token0.balanceOf(bob.address)).toString()
      );
      console.log(
        "Bob token1 balance before withdrawal => ",
        (await token1.balanceOf(bob.address)).toString()
      );
      await pickleJar.connect(bob).withdrawAll();

      console.log(
        "Bob token0 balance after withdrawal => ",
        (await token0.balanceOf(bob.address)).toString()
      );
      console.log(
        "Bob token1 balance after withdrawal => ",
        (await token1.balanceOf(bob.address)).toString()
      );

      await harvest();

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
        (await token0.balanceOf(alice.address)).toString()
      );
      console.log(
        "Alice token1 balance before withdrawal => ",
        (await token1.balanceOf(alice.address)).toString()
      );
      await pickleJar.connect(alice).withdrawAll();

      console.log(
        "Alice token0 balance after withdrawal => ",
        (await token0.balanceOf(alice.address)).toString()
      );
      console.log(
        "Alice token1 balance after withdrawal => ",
        (await token1.balanceOf(alice.address)).toString()
      );

      console.log("=============== charles withdraw ==============");
      console.log(
        "Charles token0 balance before withdrawal => ",
        (await token0.balanceOf(charles.address)).toString()
      );
      console.log(
        "Charles token1 balance before withdrawal => ",
        (await token1.balanceOf(charles.address)).toString()
      );
      await pickleJar.connect(charles).withdrawAll();

      console.log(
        "Charles token0 balance after withdrawal => ",
        (await token0.balanceOf(charles.address)).toString()
      );
      console.log(
        "Charles token1 balance after withdrawal => ",
        (await token1.balanceOf(charles.address)).toString()
      );

      console.log("------------------ Finished -----------------------");

      console.log(
        "Treasury token0 balance => ",
        (await token0.balanceOf(treasury.address)).toString()
      );
      console.log(
        "Treasury token1 balance => ",
        (await token1.balanceOf(treasury.address)).toString()
      );

      console.log(
        "Strategy token0 balance => ",
        (await token0.balanceOf(strategy.address)).toString()
      );
      console.log(
        "Strategy token1 balance => ",
        (await token1.balanceOf(strategy.address)).toString()
      );
      console.log(
        "PickleJar token0 balance => ",
        (await token0.balanceOf(pickleJar.address)).toString()
      );
      console.log(
        "PickleJar token1 balance => ",
        (await token1.balanceOf(pickleJar.address)).toString()
      );
    });

    const deposit = async (
      user: SignerWithAddress,
      depositA: BigNumber,
      depositB: BigNumber
    ) => {
      if (!depositA.eq(0))
        await token0.connect(user).approve(pickleJar.address, depositA);
      if (!depositB.eq(0))
        await token1.connect(user).approve(pickleJar.address, depositB);
      console.log("depositA => ", depositA.toString());
      console.log(
        "depositA Before Deposit: ",
        (await token0.balanceOf(user.address)).toString()
      );
      console.log("depositB => ", depositB.toString());
      console.log(
        "depositB Before Deposit: ",
        (await token1.balanceOf(user.address)).toString()
      );
      console.log(
        "Strategy token0 Before Deposit: ",
        (await token0.balanceOf(strategy.address)).toString()
      );
      console.log(
        "Strategy token1 Before Deposit: ",
        (await token1.balanceOf(strategy.address)).toString()
      );

      await pickleJar.connect(user).deposit(depositA, depositB);

      console.log(
        "Strategy token0 After Deposit: ",
        (await token0.balanceOf(strategy.address)).toString()
      );
      console.log(
        "Strategy token1 After Deposit: ",
        (await token1.balanceOf(strategy.address)).toString()
      );
    };

    const depositWithEthToken1 = async (
      user: SignerWithAddress,
      depositA: BigNumber,
      depositB: BigNumber
    ) => {
      await token0.connect(user).approve(pickleJar.address, depositA);
      console.log("depositA => ", depositA.toString());
      console.log("depositB => ", depositB.toString());
      console.log(
        "User Balance before => ",
        (await user.getBalance()).toString()
      );
      await pickleJar.connect(user).deposit(depositA, 0, { value: depositB });
      console.log(
        "User Balance after => ",
        (await user.getBalance()).toString()
      );

      console.log("");
    };

    const depositWithEthToken0 = async (
      user: SignerWithAddress,
      depositA: BigNumber,
      depositB: BigNumber
    ) => {
      await token1.connect(user).approve(pickleJar.address, depositB);
      console.log("depositA => ", depositA.toString());
      console.log("depositB => ", depositB.toString());
      console.log(
        "User Balance before => ",
        (await ethers.provider.getBalance(user.address)).toString()
      );
      await pickleJar.connect(user).deposit(0, depositB, { value: depositA });
      console.log(
        "User Balance after => ",
        (await ethers.provider.getBalance(user.address)).toString()
      );
    };

    const trade = async (_inputToken: string, _outputToken: string) => {
      const input = await getContractAt("src/lib/erc20.sol:ERC20", _inputToken);
      const poolFee = await pool.fee();
      const aliceAddress = alice.address;
      const amount = await input.balanceOf(alice.address);

      const path = ethers.utils.solidityPack(
        ["address", "uint24", "address"],
        [_inputToken, poolFee, _outputToken]
      );
      await input.connect(alice).approve(router.address, amount);
      await router.connect(alice).exactInput({
        path,
        recipient: aliceAddress,
        amountIn: amount,
        amountOutMinimum: 0,
      });
    };

    const simulateTrading = async () => {
      for (let i = 0; i < 50; i++) {
        await trade(token0.address, token1.address);
        await trade(token1.address, token0.address);
      }
    };

    const harvest = async () => {
      console.log("============ Harvest Started ==============");

      console.log(
        "Ratio before harvest => ",
        (await pickleJar.getRatio()).toString()
      );
      console.log(
        "Harvestable => ",
        (await strategy.getHarvestable()).toString()
      );
      await increaseTime(13); //travel 1 block
      await increaseBlock(1);
      await strategy.harvest();
      console.log(
        "Ratio after harvest => ",
        (await pickleJar.getRatio()).toString()
      );
      console.log("============ Harvest Ended ==============");
    };

    const rebalance = async () => {
      console.log("============ Rebalance Started ==============");

      console.log(
        "Ratio before rebalance => ",
        (await pickleJar.getRatio()).toString()
      );
      console.log(
        "TickLower before rebalance => ",
        (await pickleJar.getLowerTick()).toString()
      );
      console.log(
        "TickUpper before rebalance => ",
        (await pickleJar.getUpperTick()).toString()
      );
      console.log(
        "Strategy token0 Before Rebalance: ",
        (await token0.balanceOf(strategy.address)).toString()
      );
      console.log(
        "Strategy token1 Before Rebalance: ",
        (await token1.balanceOf(strategy.address)).toString()
      );
      await strategy.rebalance();
      console.log(
        "Ratio after rebalance => ",
        (await pickleJar.getRatio()).toString()
      );
      console.log(
        "TickLower after rebalance => ",
        (await pickleJar.getLowerTick()).toString()
      );
      console.log(
        "TickUpper after rebalance => ",
        (await pickleJar.getUpperTick()).toString()
      );
      console.log(
        "Strategy token0 After Rebalance: ",
        (await token0.balanceOf(strategy.address)).toString()
      );
      console.log(
        "Strategy token1 After Rebalance: ",
        (await token1.balanceOf(strategy.address)).toString()
      );
      console.log("============ Rebalance Ended ==============");
    };
  });
};
