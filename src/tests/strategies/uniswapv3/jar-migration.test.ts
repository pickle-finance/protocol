import "@nomicfoundation/hardhat-toolbox";
import {ethers} from "hardhat";
import {loadFixture, setBalance} from "@nomicfoundation/hardhat-network-helpers";
import {BigNumber, Contract} from "ethers";
import {expect, getContractAt} from "../../utils/testHelper";
import {callExecuteToProxy, sendGnosisSafeTxn} from "../../utils/multisigHelper";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

export const doJarMigrationTest = async (
  strategyContractName: string,
  badStrategyAddress: string,
  nativeAmountToSwap: number
) => {
  describe("UniV3 jar + strategy migration", () => {
    const initialSetupFixture = async () => {
      const [governance, alice, bob, charles, fred] = await ethers.getSigners();

      const badStrategy = await getContractAt(strategyContractName, badStrategyAddress);
      const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await badStrategy.token0());
      const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await badStrategy.token1());

      // Transfer governance on bad strategy
      const timelockAddress = await badStrategy.governance();
      await sendGnosisSafeTxn(timelockAddress, badStrategy, "setTimelock", [governance.address]);

      // Controller setup
      const controllerContractName = "/src/optimism/controller-v7.sol:ControllerV7";
      // const controllerContractName = "/src/controller-v7.sol:ControllerV7";
      const controllerAddress = await badStrategy.controller();
      const controller = await ethers.getContractAt(controllerContractName, controllerAddress);
      const controllerGovernance = await controller.governance();
      const controllerTimelock = await controller.timelock();

      // New strategy setup
      const poolAddr = await badStrategy.pool();
      const poolAbi = [
        "function tickSpacing() view returns(int24)",
        "function token0() view returns(address)",
        "function token1() view returns(address)",
        "function fee() view returns(uint24)",
      ];
      const pool = await ethers.getContractAt(poolAbi, poolAddr);
      const tickSpacing = await pool.tickSpacing();
      const utick = await badStrategy.tick_upper();
      const ltick = await badStrategy.tick_lower();
      const tickRangeMultiplier = (utick - ltick) / 2 / tickSpacing;

      const strategyContractFactory = await ethers.getContractFactory(strategyContractName);
      const newStrategy = await strategyContractFactory.deploy(
        tickRangeMultiplier,
        governance.address,
        governance.address,
        controller.address,
        governance.address
      );
      const native = await getContractAt("src/lib/erc20.sol:ERC20", await newStrategy.native());

      // New jar setup
      const oldJar = await controller.jars(pool.address);
      expect(await token0.balanceOf(oldJar)).to.be.eq(
        BigNumber.from(0),
        `Old jar still have ${await token0.symbol()} balance!`
      );
      expect(await token1.balanceOf(oldJar)).to.be.eq(
        BigNumber.from(0),
        `Old jar still have ${await token1.symbol()} balance!`
      );

      const jarContract = "src/optimism/pickle-jar-univ3.sol:PickleJarUniV3";
      const jarContractFactory = await ethers.getContractFactory(jarContract);
      const jarName = `pickling ${await token0.symbol()}/${await token1.symbol()} Jar`;
      const jarSymbol = `p${await token0.symbol()}${await token1.symbol()}`;
      const jar = await jarContractFactory.deploy(
        jarName,
        jarSymbol,
        pool.address,
        native.address,
        governance.address,
        governance.address,
        controller.address
      );
      await sendGnosisSafeTxn(controllerGovernance, controller, "setJar", [poolAddr, jar.address]);

      // Transfer Liquidity position from the bad strategy to alice
      const tokenId = await badStrategy.tokenId();
      const nftManAddr = await badStrategy.nftManager();
      const nftManAbi = [
        "function transferFrom(address from, address to, uint256 tokenId)",
        "function ownerOf(uint256) view returns(address)",
        "function WETH9() view returns(address)",
        "function decreaseLiquidity(tuple(uint256 tokenId, uint128 liquidity, uint256 amount0Min, uint256 amount1Min, uint256 deadline)) payable returns(uint256 amount0, uint256 amount1)",
        "function collect(tuple(uint256 tokenId, address recipient, uint128 amount0Max, uint128 amount1Max)) payable returns(uint256 amount0, uint256 amount1)",
        "function positions(uint256) view returns(uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)",
      ];
      const nftManContract = await ethers.getContractAt(nftManAbi, nftManAddr);

      await callExecuteToProxy(governance, badStrategy, nftManContract, "transferFrom", [
        badStrategy.address,
        alice.address,
        tokenId,
      ]);

      // Transfer badstrat dust to alice
      const badStratBal0: BigNumber = await token0.balanceOf(badStrategy.address);
      const badStratBal1: BigNumber = await token1.balanceOf(badStrategy.address);
      if (!badStratBal0.isZero()) {
        await callExecuteToProxy(governance, badStrategy, token0, "transfer", [alice.address, badStratBal0]);
      }
      if (!badStratBal1.isZero()) {
        await callExecuteToProxy(governance, badStrategy, token1, "transfer", [alice.address, badStratBal1]);
      }

      // Remove all liquidity from the NFT, then send NFT back to the badStrategy
      const {liquidity} = await nftManContract.positions(tokenId);
      const deadline = Math.floor(Date.now() / 1000) + 300;
      const [amount0, amount1] = await nftManContract
        .connect(alice)
        .callStatic.decreaseLiquidity([tokenId, liquidity, 0, 0, deadline]);
      await nftManContract.connect(alice).decreaseLiquidity([tokenId, liquidity, 0, 0, deadline]);
      await nftManContract.connect(alice).collect([tokenId, alice.address, amount0.mul(2), amount1.mul(2)]);
      await nftManContract.connect(alice).transferFrom(alice.address, badStrategy.address, tokenId);

      // Approve and set the new strategy on the controller
      await sendGnosisSafeTxn(controllerTimelock, controller, "approveStrategy", [poolAddr, newStrategy.address]);
      await sendGnosisSafeTxn(controllerGovernance, controller, "setStrategy", [poolAddr, newStrategy.address]);

      // Mint initial position on the new strategy
      const aliceBalance0 = await token0.balanceOf(alice.address);
      const aliceBalance1 = await token1.balanceOf(alice.address);

      await token0.connect(alice).transfer(newStrategy.address, aliceBalance0.div(10));
      await token1.connect(alice).transfer(newStrategy.address, aliceBalance1.div(10));

      await newStrategy.connect(governance).rebalance();

      // UniV3 router
      const routerAbi = [
        "function exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountIn, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96)) payable returns(uint256 amountOut)",
        "function exactInput((bytes path,address recipient,uint256 amountIn,uint256 amountOutMinimum)) payable returns (uint256 amountOut)",
        "function WETH9() view returns(address)",
        "function factory() view returns(address)",
      ];
      const routerAddr = await newStrategy.univ3Router();
      const router = await ethers.getContractAt(routerAbi, routerAddr);

      return {
        badStrategy,
        newStrategy,
        jar,
        governance,
        token0,
        token1,
        native,
        alice,
        bob,
        charles,
        fred,
        controller,
        controllerGovernance,
        router,
        pool,
      };
    };

    it("Alice making initial deposit", async () => {
      const {governance, newStrategy, token0, token1, alice, jar} = await loadFixture(initialSetupFixture);
      const token0Symbol = await token0.symbol();
      const token1Symbol = await token1.symbol();
      const strategyAmount0Before = await token0.balanceOf(newStrategy.address);
      const strategyAmount1Before = await token1.balanceOf(newStrategy.address);

      // Deposit all tokens in the jar
      const aliceAmount0Before = await token0.balanceOf(alice.address);
      const aliceAmount1Before = await token1.balanceOf(alice.address);
      await token0.connect(alice).approve(jar.address, aliceAmount0Before);
      await token1.connect(alice).approve(jar.address, aliceAmount1Before);
      await jar.connect(alice).deposit(aliceAmount0Before, aliceAmount1Before);

      // Transfer refunded tokens to the strategy and call rebalance
      const aliceRefundAmount0 = await token0.balanceOf(alice.address);
      const aliceRefundAmount1 = await token1.balanceOf(alice.address);
      await token0.connect(alice).transfer(newStrategy.address, aliceRefundAmount0);
      await token1.connect(alice).transfer(newStrategy.address, aliceRefundAmount1);
      await newStrategy.connect(governance).rebalance();
      const aliceAmount0After = await token0.balanceOf(alice.address);
      const aliceAmount1After = await token1.balanceOf(alice.address);
      const alicePTokenBalance: BigNumber = await jar.balanceOf(alice.address);

      console.log("==Alice==");
      console.log(token0Symbol + " before: " + aliceAmount0Before.toString());
      console.log(token1Symbol + " before: " + aliceAmount1Before.toString());
      console.log(token0Symbol + " after: " + aliceAmount0After.toString());
      console.log(token1Symbol + " after: " + aliceAmount1After.toString());
      console.log("pToken after: " + alicePTokenBalance.toString());
      expect(aliceAmount0After).to.be.eq(BigNumber.from(0), "Alice didn't deposit all token0 amounts!");
      expect(aliceAmount1After).to.be.eq(BigNumber.from(0), "Alice didn't deposit all token1 amounts!");
      expect(alicePTokenBalance.gt(0)).to.be.eq(true, "Deposit failed! Alice didn't get any pTokens.");

      console.log("==Strategy==");
      console.log(token0Symbol + " before: " + strategyAmount0Before.toString());
      console.log(token1Symbol + " before: " + strategyAmount1Before.toString());
      console.log(token0Symbol + " after: " + (await token0.balanceOf(newStrategy.address)).toString());
      console.log(token1Symbol + " after: " + (await token1.balanceOf(newStrategy.address)).toString());
    });

    it("Should perform deposits and withdrawals correctly", async () => {
      const {
        governance,
        controller,
        controllerGovernance,
        newStrategy,
        token0,
        token1,
        native,
        alice,
        bob,
        charles,
        fred,
        jar,
        router,
        pool,
      } = await loadFixture(initialSetupFixture);

      const treasuryAddress = await controller.treasury();
      const treasuryToken0Before = await token0.balanceOf(treasuryAddress);
      const treasuryToken1Before = await token1.balanceOf(treasuryAddress);
      const treasuryNativeBefore = await native.balanceOf(treasuryAddress);
      const token0Symbol = await token0.symbol();
      const token1Symbol = await token1.symbol();
      const token0Decimals = await token0.decimals();
      const token1Decimals = await token1.decimals();

      // Set users' ETH balances so they can deposit in jars
      const nativeAmountToSwapBN = ethers.utils.parseEther(nativeAmountToSwap.toString());
      const wethTopupAmount = nativeAmountToSwapBN.mul(2).add(ethers.utils.parseEther("1"));
      await setBalance(bob.address, wethTopupAmount);
      await setBalance(charles.address, wethTopupAmount);
      await setBalance(fred.address, wethTopupAmount);

      // Fill users' token0/token1 balances
      await buyToken(bob, nativeAmountToSwapBN, token0, router);
      await buyToken(charles, nativeAmountToSwapBN, token0, router);
      await buyToken(fred, nativeAmountToSwapBN, token0, router);
      await buyToken(bob, nativeAmountToSwapBN, token1, router);
      await buyToken(charles, nativeAmountToSwapBN, token1, router);
      await buyToken(fred, nativeAmountToSwapBN, token1, router);

      console.log(
        "Jar " + token0Symbol + " balance before test => ",
        bigToNumber(await token0.balanceOf(jar.address), token0Decimals)
      );
      console.log(
        "Jar " + token1Symbol + " balance before test => ",
        bigToNumber(await token1.balanceOf(jar.address), token1Decimals)
      );
      console.log(
        "Strategy " + token0Symbol + " balance before test => ",
        bigToNumber(await token0.balanceOf(newStrategy.address), token0Decimals)
      );
      console.log(
        "Strategy " + token1Symbol + " balance before test => ",
        bigToNumber(await token1.balanceOf(newStrategy.address), token1Decimals)
      );

      // Alice has to deposit first to preserve old jar users' shares
      const aliceAmount0Before = await token0.balanceOf(alice.address);
      const aliceAmount1Before = await token1.balanceOf(alice.address);
      await token0.connect(alice).approve(jar.address, aliceAmount0Before);
      await token1.connect(alice).approve(jar.address, aliceAmount1Before);
      await jar.connect(alice).deposit(aliceAmount0Before, aliceAmount1Before);
      const aliceRefundAmount0 = await token0.balanceOf(alice.address);
      const aliceRefundAmount1 = await token1.balanceOf(alice.address);
      await token0.connect(alice).transfer(newStrategy.address, aliceRefundAmount0);
      await token1.connect(alice).transfer(newStrategy.address, aliceRefundAmount1);
      await newStrategy.connect(governance).rebalance();

      // New users depositing into the jar
      // Fred deposit
      console.log("\n===============Fred Deposit==============");
      console.log(
        "Fred " + token0Symbol + " balance before deposit => ",
        bigToNumber(await token0.balanceOf(fred.address), token0Decimals)
      );
      console.log(
        "Fred " + token1Symbol + " balance before deposit => ",
        bigToNumber(await token1.balanceOf(fred.address), token1Decimals)
      );
      await depositIntoJar(fred, jar, token0, token1);
      console.log(
        "Fred " + token0Symbol + " balance after deposit => ",
        bigToNumber(await token0.balanceOf(fred.address), token0Decimals)
      );
      console.log(
        "Fred " + token1Symbol + " balance after deposit => ",
        bigToNumber(await token1.balanceOf(fred.address), token1Decimals)
      );

      // Bob & Charles deposits
      console.log("\n===============Bob Deposit==============");
      console.log(
        "Bob " + token0Symbol + " balance before deposit => ",
        bigToNumber(await token0.balanceOf(bob.address), token0Decimals)
      );
      console.log(
        "Bob " + token1Symbol + " balance before deposit => ",
        bigToNumber(await token1.balanceOf(bob.address), token1Decimals)
      );
      await depositIntoJar(bob, jar, token0, token1);
      console.log(
        "Bob " + token0Symbol + " balance after deposit => ",
        bigToNumber(await token0.balanceOf(bob.address), token0Decimals)
      );
      console.log(
        "Bob " + token1Symbol + " balance after deposit => ",
        bigToNumber(await token1.balanceOf(bob.address), token1Decimals)
      );

      console.log("\n===============Charles Deposit==============");
      console.log(
        "Charles " + token0Symbol + " balance before deposit => ",
        bigToNumber(await token0.balanceOf(charles.address), token0Decimals)
      );
      console.log(
        "Charles " + token1Symbol + " balance before deposit => ",
        bigToNumber(await token1.balanceOf(charles.address), token1Decimals)
      );
      await depositIntoJar(charles, jar, token0, token1);
      console.log(
        "Charles " + token0Symbol + " balance after deposit => ",
        bigToNumber(await token0.balanceOf(charles.address), token0Decimals)
      );
      console.log(
        "Charles " + token1Symbol + " balance after deposit => ",
        bigToNumber(await token1.balanceOf(charles.address), token1Decimals)
      );

      // Users' shares should be close
      const fredShare: BigNumber = await jar.balanceOf(fred.address);
      const bobShare: BigNumber = await jar.balanceOf(bob.address);
      const charlesShare: BigNumber = await jar.balanceOf(charles.address);
      console.log("Fred share amount => ", bigToNumber(fredShare));
      console.log("Bob share amount => ", bigToNumber(bobShare));
      console.log("Charles share amount => ", bigToNumber(charlesShare));
      expect(fredShare).to.be.eqApprox(bobShare);
      expect(fredShare).to.be.eqApprox(charlesShare);

      console.log("\n===============Strategy Harvest==============");
      const liquidityBefore = await newStrategy.liquidityOfPool();
      console.log("Strategy liquidity before harvest => ", bigToNumber(liquidityBefore, 0));
      await simulateSwaps(router, pool, nativeAmountToSwapBN.mul(20));
      await newStrategy.connect(governance).harvest();
      const liquidityAfter: BigNumber = await newStrategy.liquidityOfPool();
      console.log("Strategy liquidity after harvest => ", bigToNumber(liquidityAfter, 0));
      expect(liquidityAfter.gt(liquidityBefore)).to.be.eq(true, "Harvest failed! Liquidity didn't increase.");

      console.log("\n===============Fred partial withdraw==============");
      console.log(
        "Fred " + token0Symbol + " balance before withdrawal => ",
        bigToNumber(await token0.balanceOf(fred.address), token0Decimals)
      );
      console.log(
        "Fred " + token1Symbol + " balance before withdrawal => ",
        bigToNumber(await token1.balanceOf(fred.address), token1Decimals)
      );
      await jar.connect(fred).withdraw(fredShare.div(2));
      console.log(
        "Fred " + token0Symbol + " balance after withdrawal => ",
        bigToNumber(await token0.balanceOf(fred.address), token0Decimals)
      );
      console.log(
        "Fred " + token1Symbol + " balance after withdrawal => ",
        bigToNumber(await token1.balanceOf(fred.address), token1Decimals)
      );
      console.log("Fred shares remaining => ", bigToNumber(await jar.balanceOf(fred.address)));

      console.log("\n===============Bob withdraw==============");
      console.log(
        "Bob " + token0Symbol + " balance before withdrawal => ",
        bigToNumber(await token0.balanceOf(bob.address), token0Decimals)
      );
      console.log(
        "Bob " + token1Symbol + " balance before withdrawal => ",
        bigToNumber(await token1.balanceOf(bob.address), token1Decimals)
      );
      await jar.connect(bob).withdrawAll();
      const bobBalance0After = await token0.balanceOf(bob.address);
      const bobBalance1After = await token1.balanceOf(bob.address);
      console.log(
        "Bob " + token0Symbol + " balance after withdrawal => ",
        bigToNumber(bobBalance0After, token0Decimals)
      );
      console.log(
        "Bob " + token1Symbol + " balance after withdrawal => ",
        bigToNumber(bobBalance1After, token1Decimals)
      );

      console.log("Rebalancing...");
      await newStrategy.connect(governance).rebalance();

      // Controller withdraws tokens from strategy to jar. Users should be able to withdraw when strategy is empty
      console.log("\n=============== Controller withdraw ===============");
      console.log(
        "Jar " + token0Symbol + " balance before withdrawal => ",
        bigToNumber(await token0.balanceOf(jar.address), token0Decimals)
      );
      console.log(
        "Jar " + token1Symbol + " balance before withdrawal => ",
        bigToNumber(await token1.balanceOf(jar.address), token1Decimals)
      );
      await sendGnosisSafeTxn(controllerGovernance, controller, "withdrawAll", [pool.address]);
      console.log(
        "Jar " + token0Symbol + " balance after withdrawal => ",
        bigToNumber(await token0.balanceOf(jar.address), token0Decimals)
      );
      console.log(
        "Jar " + token1Symbol + " balance after withdrawal => ",
        bigToNumber(await token1.balanceOf(jar.address), token1Decimals)
      );

      console.log("\n===============Fred Full withdraw==============");
      console.log(
        "Fred " + token0Symbol + " balance before withdrawal => ",
        bigToNumber(await token0.balanceOf(fred.address), token0Decimals)
      );
      console.log(
        "Fred " + token1Symbol + " balance before withdrawal => ",
        bigToNumber(await token1.balanceOf(fred.address), token1Decimals)
      );
      await jar.connect(fred).withdrawAll();
      const fredBalance0After = await token0.balanceOf(fred.address);
      const fredBalance1After = await token1.balanceOf(fred.address);
      console.log(
        "Fred " + token0Symbol + " balance after withdrawal => ",
        bigToNumber(fredBalance0After, token0Decimals)
      );
      console.log(
        "Fred " + token1Symbol + " balance after withdrawal => ",
        bigToNumber(fredBalance1After, token1Decimals)
      );

      console.log("\n=============== charles withdraw ==============");
      console.log(
        "Charles " + token0Symbol + " balance before withdrawal => ",
        bigToNumber(await token0.balanceOf(charles.address), token0Decimals)
      );
      console.log(
        "Charles " + token1Symbol + " balance before withdrawal => ",
        bigToNumber(await token1.balanceOf(charles.address), token1Decimals)
      );
      await jar.connect(charles).withdrawAll();
      const charlesBalance0After = await token0.balanceOf(charles.address);
      const charlesBalance1After = await token1.balanceOf(charles.address);
      console.log(
        "Charles " + token0Symbol + " balance after withdrawal => ",
        bigToNumber(charlesBalance0After, token0Decimals)
      );
      console.log(
        "Charles " + token1Symbol + " balance after withdrawal => ",
        bigToNumber(charlesBalance1After, token1Decimals)
      );

      expect(bobBalance0After).to.be.eqApprox(charlesBalance0After);
      expect(bobBalance0After).to.be.eqApprox(fredBalance0After);
      expect(bobBalance1After).to.be.eqApprox(charlesBalance1After);
      expect(bobBalance1After).to.be.eqApprox(fredBalance1After);

      console.log("\n------------------ Finished -----------------------");
      const treasuryToken0After = await token0.balanceOf(treasuryAddress);
      const treasuryToken1After = await token1.balanceOf(treasuryAddress);
      const treasuryNativeAfter = await native.balanceOf(treasuryAddress);
      console.log(
        "Treasury " + token0Symbol + " gained => ",
        bigToNumber(treasuryToken0After.sub(treasuryToken0Before), token0Decimals)
      );
      console.log(
        "Treasury " + token1Symbol + " gained => ",
        bigToNumber(treasuryToken1After.sub(treasuryToken1Before), token1Decimals)
      );
      console.log("Treasury native gained => ", bigToNumber(treasuryNativeAfter.sub(treasuryNativeBefore)));
      console.log(
        "Strategy " + token0Symbol + " balance => ",
        bigToNumber(await token0.balanceOf(newStrategy.address), token0Decimals)
      );
      console.log(
        "Strategy " + token1Symbol + " balance => ",
        bigToNumber(await token1.balanceOf(newStrategy.address), token1Decimals)
      );
      console.log("Strategy native balance => ", bigToNumber(await native.balanceOf(newStrategy.address)));
      console.log(
        "Jar " + token0Symbol + " balance => ",
        bigToNumber(await token0.balanceOf(jar.address), token0Decimals)
      );
      console.log(
        "Jar " + token1Symbol + " balance => ",
        bigToNumber(await token1.balanceOf(jar.address), token1Decimals)
      );
      console.log("Jar native balance => ", bigToNumber(await native.balanceOf(jar.address)));
    });
  });

  // Helpers
  const bigToNumber = (amount: BigNumber, decimals = 18) => parseFloat(ethers.utils.formatUnits(amount, decimals));

  const buyToken = async (buyer: SignerWithAddress, ethAmountToSwap: BigNumber, token: Contract, router: Contract) => {
    // Convert ETH to WETH
    const wethAddr = await router.WETH9();
    const wethDepositAbi = ["function deposit() payable", "function approve(address,uint256) returns(bool)"];
    const weth = await ethers.getContractAt(wethDepositAbi, wethAddr);
    await weth.connect(buyer).deposit({value: ethAmountToSwap});

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
    const pathEncoded = ethers.utils.solidityPack(
      ["address", "uint24", "address"],
      [wethAddr, bestPoolFee, token.address]
    );
    const exactInputParams = [pathEncoded, buyer.address, ethAmountToSwap, 0];
    await weth.connect(buyer).approve(router.address, ethers.constants.MaxUint256);
    await router.connect(buyer).exactInput(exactInputParams);
  };

  const simulateSwaps = async (router: Contract, pool: Contract, nativeAmountToSwap: BigNumber) => {
    const [alice] = await ethers.getSigners();
    const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await pool.token0());
    const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await pool.token1());
    const initialBalance0 = await token0.balanceOf(alice.address);
    const initialBalance1 = await token1.balanceOf(alice.address);
    await setBalance(alice.address, nativeAmountToSwap.add(ethers.utils.parseEther("1")));

    // Convert native to token0
    await buyToken(alice, nativeAmountToSwap, token0, router);

    // Swap token0 to token1
    const amount0ToSwap = (await token0.balanceOf(alice.address)).sub(initialBalance0);
    const pathEncoded0 = ethers.utils.solidityPack(
      ["address", "uint24", "address"],
      [token0.address, await pool.fee(), token1.address]
    );
    const exactInputParams0 = [pathEncoded0, alice.address, amount0ToSwap, 0];
    await token0.connect(alice).approve(router.address, ethers.constants.MaxUint256);
    await router.connect(alice).exactInput(exactInputParams0);

    // Swap token1 to token0
    const amount1ToSwap = (await token1.balanceOf(alice.address)).sub(initialBalance1);
    const pathEncoded1 = ethers.utils.solidityPack(
      ["address", "uint24", "address"],
      [token1.address, await pool.fee(), token0.address]
    );
    const exactInputParams1 = [pathEncoded1, alice.address, amount1ToSwap, 0];
    await token1.connect(alice).approve(router.address, ethers.constants.MaxUint256);
    await router.connect(alice).exactInput(exactInputParams1);

    // Burn the residuals
    const amount0ToBurn = (await token0.balanceOf(alice.address)).sub(initialBalance0);
    const amount1ToBurn = (await token1.balanceOf(alice.address)).sub(initialBalance1);
    await token0.connect(alice).transfer("0x0000000000000000000000000000000000000001", amount0ToBurn);
    await token1.connect(alice).transfer("0x0000000000000000000000000000000000000001", amount1ToBurn);
  };

  const depositIntoJar = async (user: SignerWithAddress, jar: Contract, token0: Contract, token1: Contract) => {
    const token0Bal = await token0.balanceOf(user.address);
    const token1Bal = await token1.balanceOf(user.address);
    await token0.connect(user).approve(jar.address, token0Bal);
    await token1.connect(user).approve(jar.address, token1Bal);
    await jar.connect(user).deposit(token0Bal, token1Bal);
  };
};
