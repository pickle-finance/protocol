import "@nomicfoundation/hardhat-toolbox";
import {ethers} from "hardhat";
import {setBalance, loadFixture, mine} from "@nomicfoundation/hardhat-network-helpers";
import {expect, getContractAt, deployContract, toWei, unlockAccount} from "../utils/testHelper";
import {BigNumber, Contract} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

describe(`PickleRebalancingKeeper`, () => {
  const keeperContractName: string = "src/optimism/chainlinkKeeper.sol:PickleRebalancingKeeper";
  const uniV3StrategyContractName: string =
    "src/strategies/optimism/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyEthUsdcUniV3Optimism";
  const uniV3Strategy1Address: string = "0x1570B5D17a0796112263F4E3FAeee53459B41A49";
  const uniV3Strategy2Address: string = "0x754ece9AC6b3FF9aCc311261EC82Bd1B69b8E00B";
  const wethAddress: string = "0x4200000000000000000000000000000000000006";
  const strat1WethAmount: BigNumber = toWei(5000);
  const strat2WethAmount: BigNumber = toWei(9000);
  const univ3RouterAddress: string = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  const poolAbi = [
    "function observe(uint32[]) view returns(int56[], uint160[])",
    "function tickSpacing() view returns(int24)",
    "function token0() view returns(address)",
    "function token1() view returns(address)",
    "function slot0() view returns(uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked)",
    "function fee() view returns(uint24)",
  ];
  const routerAbi = [
    "function exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountIn, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96)) payable returns(uint256 amountOut)",
    "function exactInput((bytes path,address recipient,uint256 amountIn,uint256 amountOutMinimum)) payable returns (uint256 amountOut)",
  ];

  const setupSingleStrategyFixture = async () => {
    const [alice, governance] = await ethers.getSigners();

    const weth = await getContractAt("src/lib/erc20.sol:ERC20", wethAddress);

    const strategy = await getContractAt(uniV3StrategyContractName, uniV3Strategy1Address);
    const stratAddrEncoded = ethers.utils.defaultAbiCoder.encode(["address[]"], [[strategy.address]]);

    const poolAddress = await strategy.pool();
    const pool = await ethers.getContractAt(poolAbi, poolAddress);

    const token0 = await pool.token0();
    const token1 = await pool.token1();
    const strat1TokenOut: string = weth.address.toLowerCase() === token0.toLowerCase() ? token1 : token0;

    const router = await ethers.getContractAt(routerAbi, univ3RouterAddress);

    const keeper = await deployContract(keeperContractName, governance.address);

    // Add strategy to keeper watch-list
    await keeper.connect(governance).addStrategies([strategy.address]);

    // Set alice weth balance so it can push strategy out of range
    await setBalance(alice.address, strat1WethAmount.add(ethers.utils.parseEther("1")));
    const wethDepositAbi = ["function deposit() payable"];
    const wethTmp = await ethers.getContractAt(wethDepositAbi, wethAddress);
    await wethTmp.connect(alice).deposit({value: strat1WethAmount});

    // Add keeper to the strategy harvesters list
    const stratStrategistAddr = await strategy.governance();
    const stratStrategist = await unlockAccount(stratStrategistAddr);
    await strategy.connect(stratStrategist).whitelistHarvesters([keeper.address]);

    return {alice, governance, weth, strategy, stratAddrEncoded, pool, strat1TokenOut, router, keeper};
  };

  const setupDoubleStrategiesFixture = async () => {
    const {alice, governance, weth, strategy, stratAddrEncoded, pool, strat1TokenOut, router, keeper} =
      await loadFixture(setupSingleStrategyFixture);

    const strategy2 = await getContractAt(uniV3StrategyContractName, uniV3Strategy2Address);

    const poolAddress = await strategy2.pool();
    const strat2Pool = await ethers.getContractAt(poolAbi, poolAddress);

    const token0 = await strat2Pool.token0();
    const token1 = await strat2Pool.token1();
    const strat2TokenOut: string = weth.address.toLowerCase() === token0.toLowerCase() ? token1 : token0;

    // Add strategy to keeper watch-list
    await keeper.connect(governance).addStrategies([strategy2.address]);

    // Set alice weth balance so it can push both strategies out of range
    await setBalance(alice.address, strat2WethAmount.add(ethers.utils.parseEther("1")));
    const wethDepositAbi = ["function deposit() payable"];
    const wethTmp = await ethers.getContractAt(wethDepositAbi, wethAddress);
    await wethTmp.connect(alice).deposit({value: strat2WethAmount});

    // Add keeper to strategy2 harvesters list
    const stratStrategistAddr = await strategy.governance();
    const stratStrategist = await unlockAccount(stratStrategistAddr);
    await strategy2.connect(stratStrategist).whitelistHarvesters([keeper.address]);

    return {
      alice,
      governance,
      weth,
      strategy1: strategy,
      strategy2,
      stratAddrEncoded,
      pool,
      strat2Pool,
      strat1TokenOut,
      strat2TokenOut,
      router,
      keeper,
    };
  };

  describe("Keeper Strategies' Watch-List Behaviours", () => {
    let pass: boolean;

    it("Only governance can remove strategies", async () => {
      pass = false;
      const {keeper, alice, strategy} = await loadFixture(setupSingleStrategyFixture);
      await keeper
        .connect(alice)
        .removeStrategy(strategy.address)
        .catch(() => {
          pass = true;
        });
      expect(pass).to.be.eq(true, "Non-governance address can remove strategy");
    });

    it("Only governance can add strategies", async () => {
      pass = true;
      const {keeper, alice} = await loadFixture(setupSingleStrategyFixture);
      await keeper
        .connect(alice)
        .addStrategies([uniV3Strategy2Address])
        .catch(() => {
          pass = true;
        });
      expect(pass).to.be.eq(true, "Non-governance address can add strategy");
    });

    it("Should not add an already watched strategy", async () => {
      pass = false;
      const {keeper, governance, strategy} = await loadFixture(setupSingleStrategyFixture);
      await keeper
        .connect(governance)
        .addStrategies([strategy.address])
        .catch(() => {
          pass = true;
        });
      expect(pass).to.be.eq(true, "Duplicate strategies can be added to keeper's watch list");
    });

    it("Should not remove a non-watched strategy", async () => {
      pass = false;
      const {keeper, governance} = await loadFixture(setupSingleStrategyFixture);
      await keeper
        .connect(governance)
        .removeStrategy(uniV3Strategy2Address)
        .catch(() => {
          pass = true;
        });
      expect(pass).to.be.eq(true, "Non-watched strategy can be removed!");
    });

    it("Should add a new strategy correctly", async () => {
      const {keeper, governance} = await loadFixture(setupSingleStrategyFixture);
      await keeper.connect(governance).addStrategies([uniV3Strategy2Address]).catch();
      const newStratAddress = await keeper.strategies(1);
      expect(newStratAddress).to.be.eq(uniV3Strategy2Address, "Failed adding new strategy");
    });
  });

  describe("checkUpkeep", () => {
    it("Should return false when no rebalance needed", async () => {
      const {keeper} = await loadFixture(setupSingleStrategyFixture);
      const [shouldUpkeep] = await keeper.callStatic.checkUpkeep("0x");
      expect(shouldUpkeep).to.be.eq(false, "checkUpkeep logic broken");
    });

    it("Should return true when a rebalance needed", async () => {
      const {keeper, strategy, weth, strat1TokenOut, alice, router} = await loadFixture(setupSingleStrategyFixture);

      // Push strategy out of range
      await pushOutOfRange(strategy, weth, strat1TokenOut, alice, router, strat1WethAmount);

      const [shouldUpkeep, data] = await keeper.callStatic.checkUpkeep("0x");
      expect(shouldUpkeep).to.be.eq(true, "checkUpkeep logic broken");

      // In solidity, bytes variable is of type Uint8Array where each 32 bytes encodes a single value
      // We need to convert it into a hex string so ethers abi coder can decode it
      const hexString = ethers.utils.hexlify(data);

      const stratsToUpkeep = ethers.utils.defaultAbiCoder.decode(
        ["address[]"],
        ethers.utils.hexDataSlice(hexString, 0)
      ) as [string[]];

      expect(stratsToUpkeep[0].length).to.be.eq(1, "checkUpkeep thinks more than one strategy requires upkeeping");
      expect(stratsToUpkeep[0][0]).to.be.eq(strategy.address, "wrong strategy address returned");
    });
  });

  describe("performUpkeep", () => {
    let pass: boolean;

    it("Should prevent rebalance when within range", async () => {
      const {keeper, governance, strategy, stratAddrEncoded} = await loadFixture(setupSingleStrategyFixture);
      const upperTickBefore = await strategy.tick_upper();
      await keeper
        .connect(governance)
        .performUpkeep(stratAddrEncoded)
        .catch(() => {});
      const upperTickAfter = await strategy.tick_upper();
      expect(upperTickBefore).to.be.eq(upperTickAfter, "Rebalance happened while within range");
    });

    it("Should prevent rebalance when strategy not added to watchlist", async () => {
      const {keeper, governance, strategy, stratAddrEncoded, weth, strat1TokenOut, alice, router} = await loadFixture(
        setupSingleStrategyFixture
      );
      // Push strategy out of range
      await pushOutOfRange(strategy, weth, strat1TokenOut, alice, router, strat1WethAmount);

      pass = false;
      await keeper.connect(governance).removeStrategy(strategy.address);
      await keeper
        .connect(governance)
        .performUpkeep(stratAddrEncoded)
        .catch(() => {
          pass = true;
        });
      expect(pass).to.be.eq(true, "Rebalanced a non-watched strategy");
      expect(await shouldRebalance(strategy.address)).to.be.eq(true, "Rebalanced a non-watched strategy");
    });

    it("Should prevent rebalance when keeper is disabled", async () => {
      pass = false;
      const {keeper, governance, strategy, stratAddrEncoded, weth, strat1TokenOut, alice, router} = await loadFixture(
        setupSingleStrategyFixture
      );
      await pushOutOfRange(strategy, weth, strat1TokenOut, alice, router, strat1WethAmount);
      await keeper.connect(governance).setDisabled(true);
      expect(await keeper.disabled()).to.be.eq(true, "governance failed to disable the keeper");
      await keeper
        .connect(governance)
        .performUpkeep(stratAddrEncoded)
        .catch(() => {
          pass = true;
        });
      expect(pass).to.be.eq(true, "Rebalanced while keeper is disabled");
      expect(await shouldRebalance(strategy.address)).to.be.eq(true, "Rebalanced while keeper is disabled");
    });

    it("Should perform a rebalance successfully", async () => {
      const {keeper, governance, strategy, weth, strat1TokenOut, alice, router} = await loadFixture(
        setupSingleStrategyFixture
      );
      await pushOutOfRange(strategy, weth, strat1TokenOut, alice, router, strat1WethAmount);
      const [, data] = await keeper.checkUpkeep("0x");
      await keeper
        .connect(governance)
        .performUpkeep(data)
        .catch(() => {});
      expect(await shouldRebalance(strategy.address)).to.be.eq(false, "Rebalance unsuccessful");
    });

    it("Should rebalance multiple strategies successfully", async () => {
      const {alice, governance, weth, strategy1, strategy2, strat1TokenOut, strat2TokenOut, router, keeper} =
        await loadFixture(setupDoubleStrategiesFixture);
      await pushOutOfRange(strategy1, weth, strat1TokenOut, alice, router, strat1WethAmount);
      await pushOutOfRange(strategy2, weth, strat2TokenOut, alice, router, strat2WethAmount);
      const [, data] = await keeper.checkUpkeep("0x");

      await keeper
        .connect(governance)
        .performUpkeep(data)
        .catch(() => {});
      expect(await shouldRebalance(strategy1.address)).to.be.eq(false, "Strategy1 rebalance unsuccessful");
      expect(await shouldRebalance(strategy2.address)).to.be.eq(false, "Strategy2 rebalance unsuccessful");
    });
  });

  const shouldRebalance = async (stratAddr: string): Promise<boolean> => {
    const strategyContract = await getContractAt(uniV3StrategyContractName, stratAddr);
    const poolContract = await ethers.getContractAt(poolAbi, await strategyContract.pool());

    const upperTick = await strategyContract.tick_upper();
    const lowerTick = await strategyContract.tick_lower();
    const range = upperTick - lowerTick;
    const limitVar = range / 10;
    const lowerLimit = lowerTick + limitVar;
    const upperLimit = upperTick - limitVar;
    const [, currentTick] = await poolContract.slot0();

    let shouldRebalance = false;
    if (currentTick < lowerLimit || currentTick > upperLimit) shouldRebalance = true;

    return shouldRebalance;
  };

  const pushOutOfRange = async (
    strategy: Contract,
    weth: Contract,
    tokenOut: string,
    alice: SignerWithAddress,
    router: Contract,
    wethAmount: BigNumber
  ) => {
    const poolContract = await ethers.getContractAt(poolAbi, await strategy.pool());

    const fee = await poolContract.fee();
    const pathEncoded = ethers.utils.solidityPack(["address", "uint24", "address"], [weth.address, fee, tokenOut]);
    const exactInputParams = [pathEncoded, alice.address, wethAmount, 0];

    //console.log("Performing swap (be patient!)");
    const allowance = await weth.allowance(alice.address, router.address);
    if (allowance.lt(wethAmount)) {
      await weth.connect(alice).approve(router.address, 0);
      await weth.connect(alice).approve(router.address, ethers.constants.MaxUint256);
    }
    await router.connect(alice).exactInput(exactInputParams);
    //console.log("Swap successful");

    // Forward blocks a bit so strategy.determineTicks() can adjust properly
    await mine(1000);

    expect(await shouldRebalance(strategy.address)).to.be.eq(
      true,
      "Couldn't push strategy out of balance. Consider a larger trade size (Hint: increase wethAmount)"
    );
  };
});

process.on("unhandledRejection", (err) => {
  console.log(err);
  process.exit(1);
});
