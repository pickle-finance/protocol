import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";
import { loadFixture, mine, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber, Contract } from "ethers";
import { deployContract, getContractAt } from "../../../utils/testHelper";
import { callExecuteToProxy, sendGnosisSafeTxn } from "../../../utils/multisigHelper";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const doRebalanceTestWithMigration = async (
  strategyContractName: string,
  badStrategyAddress: string,
  ethAmountToSwap: number,
) => {
  describe("UniV3 Strategy", () => {
    const initialSetupFixture = async () => {
      const [governance, treasury, alice, bob, charles, fred] = await ethers.getSigners();

      // Strategy setup
      const strategy = await getContractAt(strategyContractName, badStrategyAddress);

      const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
      const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());

      // Transfer governance on bad strategy
      const timelockAddress = await strategy.governance();
      await sendGnosisSafeTxn(timelockAddress, strategy, "setGovernance", [governance.address]);
      await sendGnosisSafeTxn(timelockAddress, strategy, "setTimelock", [governance.address]);

      return { strategy, governance, treasury, token0, token1, alice, bob, charles, fred };
    };

    const setupRebalanceTestFixture = async () => {
      const { governance, treasury, token0, token1, strategy: badStrat } = await loadFixture(initialSetupFixture);

      // Controller setup
      // const controllerContractName = "/src/optimism/controller-v7.sol:ControllerV7";
      const controllerContractName = "/src/optimism/controller-v7.sol:ControllerV7";
      const controller = await deployContract(controllerContractName,
        governance.address,
        governance.address,
        governance.address,
        governance.address,
        treasury.address
      )

      // Strategy setup
      const poolAddr = await badStrat.pool();
      const poolAbi = ["function tickSpacing() view returns(int24)"];
      const pool = await ethers.getContractAt(poolAbi, poolAddr);
      const tickSpacing = await pool.tickSpacing();
      const utick = await badStrat.tick_upper();
      const ltick = await badStrat.tick_lower();
      const tickRangeMultiplier = ((utick - ltick) / 2) / tickSpacing;

      const strategyContractFactory = await ethers.getContractFactory(strategyContractName);
      const strategy = await strategyContractFactory.deploy(
        tickRangeMultiplier,
        governance.address,
        governance.address,
        controller.address,
        governance.address
      );

      await controller.connect(governance).approveStrategy(poolAddr, strategy.address);
      await controller.connect(governance).setStrategy(poolAddr, strategy.address);

      // Transfer Liquidity position from the bad strategy to the new one
      const tokenId = await badStrat.tokenId();
      const nftManAddr = await badStrat.nftManager();
      const nftManAbi = [
        "function transferFrom(address from, address to, uint256 tokenId)",
        "function ownerOf(uint256) view returns(address)",
      ];
      const nftManContract = await ethers.getContractAt(nftManAbi, nftManAddr);

      await callExecuteToProxy(governance, badStrat, nftManContract, "transferFrom", [
        badStrat.address,
        strategy.address,
        tokenId,
      ]);

      // transfer badstrat remaining usdt to the new strategy
      const badStratBal0: BigNumber = await token0.balanceOf(badStrat.address);
      const badStratBal1: BigNumber = await token1.balanceOf(badStrat.address);
      if (!badStratBal0.isZero()) {
        await callExecuteToProxy(governance, badStrat, token0, "transfer", [strategy.address, badStratBal0])
      }
      if (!badStratBal1.isZero()) {
        await callExecuteToProxy(governance, badStrat, token1, "transfer", [strategy.address, badStratBal1])
      }

      return { strategy, governance, token0, token1 };
    };
    const setupMigrationFixture = async () => {
      const { governance, treasury, token0, token1, strategy: badStrat, alice, bob, charles, fred } = await loadFixture(initialSetupFixture);

      // Controller setup
      // const controllerContractName = "/src/optimism/controller-v7.sol:ControllerV7";
      const controllerContractName = "/src/controller-v6.sol:ControllerV6";
      const controllerAddr = await badStrat.controller();
      const controller = await getContractAt(controllerContractName, controllerAddr);
      const multiSigAddr = await controller.timelock();
      await sendGnosisSafeTxn(multiSigAddr, controller, "setGovernance", [governance.address]);
      await sendGnosisSafeTxn(multiSigAddr, controller, "setTimelock", [governance.address]);
      await controller.connect(governance).setStrategist(governance.address);
      await controller.connect(governance).setTreasury(treasury.address);

      // Jar setup
      const poolAddr = await badStrat.pool();
      const jarContract = "src/polygon/pickle-jar-univ3.sol:PickleJarUniV3Poly";
      const jarAddr = await controller.jars(poolAddr);
      const jar = await getContractAt(jarContract, jarAddr);

      // Strategy setup
      const poolAbi = ["function tickSpacing() view returns(int24)"];
      const pool = await ethers.getContractAt(poolAbi, poolAddr);
      const tickSpacing = await pool.tickSpacing();
      const utick = await badStrat.tick_upper();
      const ltick = await badStrat.tick_lower();
      const tickRangeMultiplier = ((utick - ltick) / 2) / tickSpacing;

      const strategyContractFactory = await ethers.getContractFactory(strategyContractName);
      const strategy = await strategyContractFactory.deploy(
        tickRangeMultiplier,
        governance.address,
        governance.address,
        controller.address,
        governance.address
      );

      const native = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.native());

      // Initial NFT creation
      // UniV3 router
      const routerAbi = [
        "function exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountIn, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96)) payable returns(uint256 amountOut)",
        "function exactInput((bytes path,address recipient,uint256 amountIn,uint256 amountOutMinimum)) payable returns (uint256 amountOut)",
        "function WETH9() view returns(address)",
        "function factory() view returns(address)",
      ];
      const routerAddr = strategy.univ3Router();
      const router = await ethers.getContractAt(routerAbi, routerAddr);
      await setBalance(governance.address, ethers.utils.parseEther(ethAmountToSwap.toString()));
      await buyToken(governance, ethers.utils.parseEther((ethAmountToSwap / 5).toFixed(0)), token0, router);
      await buyToken(governance, ethers.utils.parseEther((ethAmountToSwap / 5).toFixed(0)), token1, router);
      await token0.connect(governance).transfer(strategy.address, await token0.balanceOf(governance.address));
      await token1.connect(governance).transfer(strategy.address, await token1.balanceOf(governance.address));
      await strategy.connect(governance).rebalance();

      // Migrate liquidity
      await controller.connect(governance).approveStrategy(poolAddr, strategy.address);
      await controller.connect(governance).setStrategy(poolAddr, strategy.address);
      await jar.earn();
      await strategy.connect(governance).rebalance();

      // Set users' ETH balances so they can deposit in jars
      const wethTopupAmount = ethers.utils.parseEther((ethAmountToSwap * 2 + 1).toString());
      await setBalance(alice.address, wethTopupAmount);
      await setBalance(bob.address, wethTopupAmount);
      await setBalance(charles.address, wethTopupAmount);
      await setBalance(fred.address, wethTopupAmount);

      // Fill users' token0/token1 balances
      await buyToken(alice, ethers.utils.parseEther(ethAmountToSwap.toString()), token0, router);
      await buyToken(bob, ethers.utils.parseEther(ethAmountToSwap.toString()), token0, router);
      await buyToken(charles, ethers.utils.parseEther(ethAmountToSwap.toString()), token0, router);
      await buyToken(fred, ethers.utils.parseEther(ethAmountToSwap.toString()), token0, router);
      await buyToken(alice, ethers.utils.parseEther(ethAmountToSwap.toString()), token1, router);
      await buyToken(bob, ethers.utils.parseEther(ethAmountToSwap.toString()), token1, router);
      await buyToken(charles, ethers.utils.parseEther(ethAmountToSwap.toString()), token1, router);
      await buyToken(fred, ethers.utils.parseEther(ethAmountToSwap.toString()), token1, router);

      return { strategy, governance, treasury, jar, controller, token0, token1, native, alice, bob, charles, fred, router, tickRangeMultiplier };
    }

    describe("Strategy Rebalance", () => {
      it.only("test rebalance on bad strategy", async () => {
        const blockNumberBefore = await (await ethers.getSigners().then((x) => x[0])).provider?.getBlockNumber();
        const { governance, strategy, token0, token1 } = await loadFixture(initialSetupFixture);

        const token0name: string = await token0.symbol();
        const token1name: string = await token1.symbol();
        const token0decimals: number = await token0.decimals();
        const token1decimals: number = await token1.decimals();

        const token0balBefore: BigNumber = await token0.balanceOf(strategy.address);
        const token1balBefore: BigNumber = await token1.balanceOf(strategy.address);
        const liquidityBefore: BigNumber = await strategy.liquidityOfPool();

        await strategy.connect(governance).rebalance();

        const token0balAfter: BigNumber = await token0.balanceOf(strategy.address);
        const token1balAfter: BigNumber = await token1.balanceOf(strategy.address);
        const liquidityAfter: BigNumber = await strategy.liquidityOfPool();

        const blockNumberAfter = await governance.provider.getBlockNumber();

        console.log("\n=== Before Rebalance ===");
        console.log("Block Number Before: " + blockNumberBefore);
        console.log(token0name, "balance:", bigToNumber(token0balBefore, token0decimals));
        console.log(token1name, "balance:", bigToNumber(token1balBefore, token1decimals));
        console.log("Liquidity:", bigToNumber(liquidityBefore, 0));

        console.log("\n=== After Rebalance ===");
        console.log("Block Number After: " + blockNumberAfter);
        console.log(token0name, "balance:", bigToNumber(token0balAfter, token0decimals));
        console.log(token1name, "balance:", bigToNumber(token1balAfter, token1decimals));
        console.log("Liquidity:", bigToNumber(liquidityAfter, 0));
      });
      it.only("test rebalance on fixed strategy", async () => {
        const blockNumberBefore = await (await ethers.getSigners().then((x) => x[0])).provider?.getBlockNumber();
        const { governance, strategy, token0, token1 } = await loadFixture(setupRebalanceTestFixture);

        const token0name: string = await token0.symbol();
        const token1name: string = await token1.symbol();
        const token0decimals: number = await token0.decimals();
        const token1decimals: number = await token1.decimals();

        const token0balBefore: BigNumber = await token0.balanceOf(strategy.address);
        const token1balBefore: BigNumber = await token1.balanceOf(strategy.address);
        const liquidityBefore: BigNumber = await strategy.liquidityOfPool();

        await strategy.connect(governance).rebalance();
        // await strategy.connect(governance).rebalance();

        const token0balAfter: BigNumber = await token0.balanceOf(strategy.address);
        const token1balAfter: BigNumber = await token1.balanceOf(strategy.address);
        const liquidityAfter: BigNumber = await strategy.liquidityOfPool();

        const blockNumberAfter = await governance.provider.getBlockNumber();

        console.log("\n=== Before Rebalance ===");
        console.log("Block Number Before: " + blockNumberBefore);
        console.log(token0name, "balance:", bigToNumber(token0balBefore, token0decimals));
        console.log(token1name, "balance:", bigToNumber(token1balBefore, token1decimals));
        console.log("Liquidity:", bigToNumber(liquidityBefore, 0));

        console.log("\n=== After Rebalance ===");
        console.log("Block Number After: " + blockNumberAfter);
        console.log(token0name, "balance:", bigToNumber(token0balAfter, token0decimals));
        console.log(token1name, "balance:", bigToNumber(token1balAfter, token1decimals));
        console.log("Liquidity:", bigToNumber(liquidityAfter, 0));
      });
      it("Should perform deposits and withdrawals correctly", async () => {
        const { governance, treasury, strategy, controller, jar, token0, token1, native, alice, bob, charles, tickRangeMultiplier } = await loadFixture(setupMigrationFixture);

        const token0Decimals = await token0.decimals();
        const token1Decimals = await token1.decimals();

        // Test setTokenToNative
        // const wethAddr = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
        // const poolFee = 500;
        // const wmaticAddr = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
        // const pathEncoded = ethers.utils.solidityPack(["address", "uint24", "address"], [wethAddr, poolFee, wmaticAddr]);
        // await strategy.connect(governance).setTokenToNativeRoute(wethAddr,pathEncoded);

        console.log("Jar token0 balance before test => ", bigToNumber(await token0.balanceOf(jar.address), token0Decimals));
        console.log("Jar token1 balance before test => ", bigToNumber(await token1.balanceOf(jar.address), token1Decimals));
        console.log("Strategy token0 balance before test => ", bigToNumber(await token0.balanceOf(strategy.address), token0Decimals));
        console.log("Strategy token1 balance before test => ", bigToNumber(await token1.balanceOf(strategy.address), token1Decimals));

        // Alice deposit
        console.log("===============Alice Deposit==============");
        console.log("Alice token0 balance before deposit => ", bigToNumber(await token0.balanceOf(alice.address), token0Decimals));
        console.log("Alice token1 balance before deposit => ", bigToNumber(await token1.balanceOf(alice.address), token1Decimals));
        await depositIntoJar(alice, jar, token0, token1);
        console.log("Alice token0 balance after deposit => ", bigToNumber(await token0.balanceOf(alice.address), token0Decimals));
        console.log("Alice token1 balance after deposit => ", bigToNumber(await token1.balanceOf(alice.address), token1Decimals));
        await strategy.connect(governance).setTickRangeMultiplier(Math.floor(tickRangeMultiplier / 2));
        console.log("Rebalancing...");
        await strategy.connect(governance).rebalance();

        // Bob & Charles deposits
        console.log("===============Bob Deposit==============");
        console.log("Bob token0 balance before deposit => ", bigToNumber(await token0.balanceOf(bob.address), token0Decimals));
        console.log("Bob token1 balance before deposit => ", bigToNumber(await token1.balanceOf(bob.address), token1Decimals));
        await depositIntoJar(bob, jar, token0, token1);
        console.log("Bob token0 balance after deposit => ", bigToNumber(await token0.balanceOf(bob.address), token0Decimals));
        console.log("Bob token1 balance after deposit => ", bigToNumber(await token1.balanceOf(bob.address), token1Decimals));

        console.log("===============Charles Deposit==============");
        console.log("Charles token0 balance before deposit => ", bigToNumber(await token0.balanceOf(charles.address), token0Decimals));
        console.log("Charles token1 balance before deposit => ", bigToNumber(await token1.balanceOf(charles.address), token1Decimals));
        await depositIntoJar(charles, jar, token0, token1);
        console.log("Charles token0 balance after deposit => ", bigToNumber(await token0.balanceOf(charles.address), token0Decimals));
        console.log("Charles token1 balance after deposit => ", bigToNumber(await token1.balanceOf(charles.address), token1Decimals));

        const aliceShare = await jar.balanceOf(alice.address);
        const bobShare = await jar.balanceOf(bob.address);
        const charlesShare = await jar.balanceOf(charles.address);
        console.log("Alice share amount => ", bigToNumber(aliceShare));
        console.log("Bob share amount => ", bigToNumber(bobShare));
        console.log("Charles share amount => ", bigToNumber(charlesShare));

        console.log("===============Alice partial withdraw==============");
        console.log("Alice token0 balance before withdrawal => ", bigToNumber(await token0.balanceOf(alice.address), token0Decimals));
        console.log("Alice token1 balance before withdrawal => ", bigToNumber(await token1.balanceOf(alice.address), token1Decimals));
        await jar.connect(alice).withdraw(aliceShare.div(BigNumber.from(2)));
        console.log("Alice token0 balance after withdrawal => ", bigToNumber(await token0.balanceOf(alice.address), token0Decimals));
        console.log("Alice token1 balance after withdrawal => ", bigToNumber(await token1.balanceOf(alice.address), token1Decimals));
        console.log("Alice shares remaining => ", bigToNumber(await jar.balanceOf(alice.address)));

        await mine(60 * 60 * 24);

        console.log("===============Bob withdraw==============");
        console.log("Bob token0 balance before withdrawal => ", bigToNumber(await token0.balanceOf(bob.address), token0Decimals));
        console.log("Bob token1 balance before withdrawal => ", bigToNumber(await token1.balanceOf(bob.address), token1Decimals));
        await jar.connect(bob).withdrawAll();
        console.log("Bob token0 balance after withdrawal => ", bigToNumber(await token0.balanceOf(bob.address), token0Decimals));
        console.log("Bob token1 balance after withdrawal => ", bigToNumber(await token1.balanceOf(bob.address), token1Decimals));

        console.log("Rebalancing...");
        await strategy.connect(governance).rebalance();

        console.log("=============== Controller withdraw ===============");
        console.log("Jar token0 balance before withdrawal => ", bigToNumber(await token0.balanceOf(jar.address), token0Decimals));
        console.log("Jar token1 balance before withdrawal => ", bigToNumber(await token1.balanceOf(jar.address), token1Decimals));
        const poolAddr = strategy.pool();
        await controller.withdrawAll(poolAddr);
        console.log("Jar token0 balance after withdrawal => ", bigToNumber(await token0.balanceOf(jar.address), token0Decimals));
        console.log("Jar token1 balance after withdrawal => ", bigToNumber(await token1.balanceOf(jar.address), token1Decimals));

        console.log("===============Alice Full withdraw==============");
        console.log("Alice token0 balance before withdrawal => ", bigToNumber(await token0.balanceOf(alice.address), token0Decimals));
        console.log("Alice token1 balance before withdrawal => ", bigToNumber(await token1.balanceOf(alice.address), token1Decimals));
        await jar.connect(alice).withdrawAll();
        console.log("Alice token0 balance after withdrawal => ", bigToNumber(await token0.balanceOf(alice.address), token0Decimals));
        console.log("Alice token1 balance after withdrawal => ", bigToNumber(await token1.balanceOf(alice.address), token1Decimals));

        console.log("=============== charles withdraw ==============");
        console.log("Charles token0 balance before withdrawal => ", bigToNumber(await token0.balanceOf(charles.address), token0Decimals));
        console.log("Charles token1 balance before withdrawal => ", bigToNumber(await token1.balanceOf(charles.address), token1Decimals));
        await jar.connect(charles).withdrawAll();
        console.log("Charles token0 balance after withdrawal => ", bigToNumber(await token0.balanceOf(charles.address), token0Decimals));
        console.log("Charles token1 balance after withdrawal => ", bigToNumber(await token1.balanceOf(charles.address), token1Decimals));

        console.log("------------------ Finished -----------------------");

        console.log("Treasury token0 balance => ", bigToNumber(await token0.balanceOf(treasury.address), token0Decimals));
        console.log("Treasury token1 balance => ", bigToNumber(await token1.balanceOf(treasury.address), token1Decimals));
        console.log("Treasury native balance => ", bigToNumber(await native.balanceOf(treasury.address)));
        console.log("Strategy token0 balance => ", bigToNumber(await token0.balanceOf(strategy.address), token0Decimals));
        console.log("Strategy token1 balance => ", bigToNumber(await token1.balanceOf(strategy.address), token1Decimals));
        console.log("Strategy native balance => ", bigToNumber(await native.balanceOf(strategy.address)));
        console.log("Jar token0 balance => ", bigToNumber(await token0.balanceOf(jar.address), token0Decimals));
        console.log("Jar token1 balance => ", bigToNumber(await token1.balanceOf(jar.address), token1Decimals));
        console.log("Jar native balance => ", bigToNumber(await native.balanceOf(jar.address)));
      });
    });
  });

  const bigToNumber = (amount: BigNumber, decimals = 18) => parseFloat(ethers.utils.formatUnits(amount, decimals));

  const buyToken = async (buyer: SignerWithAddress, ethAmountToSwap: BigNumber, token: Contract, router: Contract) => {
    // Convert ETH to WETH
    const wethAddr = await router.WETH9();
    const wethDepositAbi = ["function deposit() payable", "function approve(address,uint256) returns(bool)"];
    const weth = await ethers.getContractAt(wethDepositAbi, wethAddr);
    await weth.connect(buyer).deposit({ value: ethAmountToSwap });

    if (wethAddr === token.address) return;

    // Find the best pool for the swap
    const factoryAbi = ["function getPool(address token0, address token1, uint24 fee) view returns(address)"];
    const factoryAddr = await router.factory();
    const factory = await ethers.getContractAt(factoryAbi, factoryAddr);
    const fees = [100, 500, 3000];
    let bestPoolBal: BigNumber = BigNumber.from("0");
    let bestPoolFee: number;
    for (let i = 0; i < fees.length; i++) {
      const fee = fees[i];
      const poolAddr = await factory.getPool(wethAddr, token.address, fee);
      if (poolAddr === ethers.constants.AddressZero) continue;
      const poolBalance: BigNumber = await token.balanceOf(poolAddr);
      if (poolBalance.gt(bestPoolBal)) {
        bestPoolBal = poolBalance;
        bestPoolFee = fee;
      }
    }
    if (!bestPoolFee) throw `No pool found for WETH-${await token.symbol()}`;

    // Swap
    const pathEncoded = ethers.utils.solidityPack(["address", "uint24", "address"], [wethAddr, bestPoolFee, token.address]);
    const exactInputParams = [pathEncoded, buyer.address, ethAmountToSwap, 0];
    await weth.connect(buyer).approve(router.address, ethers.constants.MaxUint256);
    await router.connect(buyer).exactInput(exactInputParams);
  }

  const depositIntoJar = async (user: SignerWithAddress, jar: Contract, token0: Contract, token1: Contract) => {
    const token0Bal = await token0.balanceOf(user.address);
    const token1Bal = await token1.balanceOf(user.address);
    await token0.connect(user).approve(jar.address, token0Bal);
    await token1.connect(user).approve(jar.address, token1Bal);
    await jar.connect(user).deposit(token0Bal, token1Bal);
  };

};


// Optimism USDC-DAI (tokenId 223464)
// doRebalanceTestWithMigration(
//   "src/strategies/optimism/uniswapv3/strategy-univ3-usdc-dai-lp.sol:StrategyUsdcDaiUniV3Optimism",
//   "0x387C985176A314c9e5D927a99724de98576812aF",
//   0.01
// )

// Optimism SUSD-USDC (tokenId 223426)
// doRebalanceTestWithMigration(
//   "src/strategies/optimism/uniswapv3/strategy-univ3-susd-usdc-lp.sol:StrategySusdUsdcUniV3Optimism",
//   "0xa99e8a5754a53bE312Fba259c7C4619cfB00E849",
//   0.01
// )

// Optimism SUSD-DAI (tokenId 223547)
// doRebalanceTestWithMigration(
//   "src/strategies/optimism/uniswapv3/strategy-univ3-susd-dai-lp.sol:StrategySusdDaiUniV3Optimism",
//   "0x1Bb40496D3074A2345d5e3Ac28b990854A7BDe34",
//   0.01
// )

// Optimism ETH-USDC (tokenId 222765)
// doRebalanceTestWithMigration(
//   "src/strategies/optimism/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyEthUsdcUniV3Optimism",
//   "0x1570B5D17a0796112263F4E3FAeee53459B41A49",
//   0.01
// )

// Optimism ETH-OP (tokenId 202867)
doRebalanceTestWithMigration(
  "src/strategies/optimism/uniswapv3/strategy-univ3-eth-op-lp.sol:StrategyEthOpUniV3Optimism",
  "0x1634e17813D54Ffc7506523D6e8bf08556207468",
  0.01,
)

// Optimism ETH-DAI (tokenId 222769)
// doRebalanceTestWithMigration(
//   "src/strategies/optimism/uniswapv3/strategy-univ3-eth-dai-lp.sol:StrategyEthDaiUniV3Optimism",
//   "0xE9936818ecd2a6930407a11C090260b5390A954d",
//   0.01,
// )

// Optimism ETH-BTC (tokenId 150971)
// doRebalanceTestWithMigration(
//   "src/strategies/optimism/uniswapv3/strategy-univ3-eth-btc-lp.sol:StrategyEthBtcUniV3Optimism",
//   "0x754ece9AC6b3FF9aCc311261EC82Bd1B69b8E00B",
//   0.01,
// )

