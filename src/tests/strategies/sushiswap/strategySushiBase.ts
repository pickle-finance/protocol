import "@nomicfoundation/hardhat-toolbox";
import {ethers} from "hardhat";
import {expect, increaseTime, getContractAt} from "../../utils/testHelper";
import {setup} from "../../utils/setupHelper";
import {NULL_ADDRESS} from "../../utils/constants";
import {BigNumber, Contract} from "ethers";
import {loadFixture, setBalance} from "@nomicfoundation/hardhat-network-helpers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

export const doTestBehaviorBase = (strategyName: string, days = 15, wantSize = 1) => {
  const shortName = strategyName.substring(strategyName.lastIndexOf(":") + 1);
  describe(`${shortName} common behavior tests`, () => {
    const initialSetupFixture = async () => {
      const [governance, treasury, devfund] = await ethers.getSigners();

      const alice = governance;
      const strategist = devfund;
      const timelock = alice;

      const [controller, strategy, jar] = await setup(
        strategyName,
        governance,
        strategist,
        timelock,
        devfund,
        treasury
      );

      // await strategy.init();

      const want = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.want());
      const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
      const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
      const native = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.native());

      // Get some want tokens into Alice wallet
      await setBalance(alice.address, ethers.utils.parseEther((wantSize * 2).toString()));
      const wNativeDepositAbi = ["function deposit() payable", "function approve(address,uint256) returns(bool)"];
      const wNativeDeposit = await ethers.getContractAt(wNativeDepositAbi, native.address);
      await wNativeDeposit.connect(alice).deposit({value: ethers.utils.parseEther(wantSize.toString())});
      await getWantFor(alice, strategy);
      const wantBalance: BigNumber = await want.balanceOf(alice.address);
      expect(wantBalance.isZero()).to.be.eq(false, "Alice failed to get some want tokens!");

      return {
        strategy,
        jar,
        controller,
        governance,
        treasury,
        timelock,
        devfund,
        strategist,
        alice,
        want,
        native,
        token0,
        token1,
      };
    };

    it("Should set the timelock correctly", async () => {
      const {strategy, timelock, devfund} = await loadFixture(initialSetupFixture);
      expect(await strategy.timelock()).to.be.eq(timelock.address, "timelock is incorrect");
      await strategy.connect(timelock).setPendingTimelock(devfund.address);
      await strategy.connect(devfund).acceptTimelock();
      expect(await strategy.timelock()).to.be.eq(devfund.address, "timelock is incorrect");
    });

    it("Should withdraw correctly", async () => {
      const {want, alice, jar: pickleJar, strategy, controller} = await loadFixture(initialSetupFixture);
      const _want: BigNumber = await want.balanceOf(alice.address);
      await want.connect(alice).approve(pickleJar.address, _want);
      await pickleJar.connect(alice).deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * days); //travel days into the future

      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      console.log("Ratio after harvest: %s", (await pickleJar.getRatio()).toString());

      let _before: BigNumber = await want.balanceOf(pickleJar.address);
      console.log("\nPicklejar balance before controller withdrawal: ", _before.toString());

      await controller.withdrawAll(want.address);

      let _after: BigNumber = await want.balanceOf(pickleJar.address);
      console.log("Picklejar balance after controller withdrawal: ", _after.toString());

      expect(_after).to.be.gt(_before, "controller withdrawAll failed");

      _before = await want.balanceOf(alice.address);
      console.log("\nAlice balance before picklejar withdrawal: ", _before.toString());

      await pickleJar.withdrawAll();

      _after = await want.balanceOf(alice.address);
      console.log("Alice balance after picklejar withdrawal: ", _after.toString());

      expect(_after).to.be.gt(_before, "picklejar withdrawAll failed");
      expect(_after).to.be.gt(_want, "no interest earned");
    });

    it("Should harvest correctly", async () => {
      const {want, alice, jar: pickleJar, strategy, native, treasury, devfund} = await loadFixture(initialSetupFixture);
      const _want: BigNumber = await want.balanceOf(alice.address);
      await want.connect(alice).approve(pickleJar.address, _want);
      await pickleJar.connect(alice).deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * days); //travel days into the future

      const pendingRewards: [string[], BigNumber[]] = await strategy.getHarvestable();
      const _before: BigNumber = await pickleJar.balance();
      let _treasuryBefore: BigNumber = await native.balanceOf(treasury.address);

      console.log("Rewards harvestable amounts:");
      pendingRewards[0].forEach((addr, i) => {
        console.log(`\t${addr}: ${pendingRewards[1][i].toString()}`);
      });
      console.log("Picklejar balance before harvest: ", _before.toString());
      console.log("💸 Treasury reward token balance before harvest: ", _treasuryBefore.toString());
      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      const _after: BigNumber = await pickleJar.balance();
      let _treasuryAfter: BigNumber = await native.balanceOf(treasury.address);
      console.log("Ratio after harvest: ", (await pickleJar.getRatio()).toString());
      console.log("\nPicklejar balance after harvest: ", _after.toString());
      console.log("💸 Treasury reward token balance after harvest: ", _treasuryAfter.toString());

      //performance fee is given
      const rewardsEarned = _treasuryAfter.sub(_treasuryBefore);
      console.log("\nPerformance fee earned by treasury: ", rewardsEarned.toString());

      expect(rewardsEarned).to.be.gt(0, "no performance fee taken");

      //withdraw
      const _devBefore: BigNumber = await want.balanceOf(devfund.address);
      _treasuryBefore = await want.balanceOf(treasury.address);
      console.log("\n👨‍🌾 Dev balance before picklejar withdrawal: ", _devBefore.toString());
      console.log("💸 Treasury balance before picklejar withdrawal: ", _treasuryBefore.toString());

      await pickleJar.withdrawAll();

      const _devAfter: BigNumber = await want.balanceOf(devfund.address);
      _treasuryAfter = await want.balanceOf(treasury.address);
      console.log("\n👨‍🌾 Dev balance after picklejar withdrawal: ", _devAfter.toString());
      console.log("💸 Treasury balance after picklejar withdrawal: ", _treasuryAfter.toString());

      //0% goes to dev
      const _devFund = _devAfter.sub(_devBefore);
      expect(_devFund).to.be.eq(0, "dev've stolen money!!!!!");

      //0% goes to treasury
      const _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
      expect(_treasuryFund).to.be.eq(0, "treasury've stolen money!!!!");
    });

    it("Should perform multiple deposits and withdrawals correctly", async () => {
      const {want, alice, jar: pickleJar, strategist} = await loadFixture(initialSetupFixture);
      const _wantHalved: BigNumber = (await want.balanceOf(alice.address)).div(2);
      await want.connect(alice).transfer(strategist.address, _wantHalved);
      await want.connect(alice).approve(pickleJar.address, _wantHalved);
      await want.connect(strategist).approve(pickleJar.address, _wantHalved);

      console.log("\nAlice starting balance: %s\n", _wantHalved.toString());

      await pickleJar.connect(alice).deposit(_wantHalved);
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 2); //travel 2 days

      await pickleJar.connect(strategist).deposit(_wantHalved);

      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 2); //travel 2 days

      // Alice withdraws half
      await pickleJar.connect(alice).withdraw(_wantHalved.div(2));

      await pickleJar.earn();

      // Strategist withdraws all
      await pickleJar.connect(strategist).withdrawAll();

      let _aliceBalanceAfter: BigNumber = await want.balanceOf(alice.address);
      let _strategistBalanceAfter: BigNumber = await want.balanceOf(strategist.address);
      console.log("\nAlice balance after half withdrawal: %s\n", _aliceBalanceAfter.toString());
      console.log("\nStrategist balance after half withdrawal: %s\n", _strategistBalanceAfter.toString());

      expect(_aliceBalanceAfter).to.be.approximately(_wantHalved.div(2), 1, "Alice withdrawal amount incorrect");

      expect(_strategistBalanceAfter).to.be.approximately(_wantHalved, 1, "Strategist withdrawal amount incorrect");

      // Alice withdraws remainder

      await pickleJar.connect(alice).withdrawAll();
      _aliceBalanceAfter = await want.balanceOf(alice.address);
      console.log("\nAlice balance after full withdrawal: %s\n", _aliceBalanceAfter.toString());
      expect(_aliceBalanceAfter).to.be.approximately(_wantHalved, 1, "Alice withdrawal amount incorrect");
    });

    it("should add, update and remove rewards correctly", async () => {
      const {strategy, strategist} = await loadFixture(initialSetupFixture);
      const encodeRouteStep = (
        isLegacy: boolean,
        legacyPath: string[] = undefined,
        tridentPath: string[][] = undefined
      ) => {
        let encodedPath: string;
        if (isLegacy) {
          encodedPath = ethers.utils.defaultAbiCoder.encode(["address[]"], [legacyPath]);
        } else {
          encodedPath = ethers.utils.defaultAbiCoder.encode(["tuple(address, bytes)[]"], [tridentPath]);
        }
        const encodedRouteStep = ethers.utils.defaultAbiCoder.encode(["bool", "bytes"], [isLegacy, encodedPath]);
        return encodedRouteStep;
      };
      const getToNativeRoute = async (rewardToken:string) => {
        const want = await strategy.want();
        let rewardToNativeRoute: string[];
        if ((await strategy.bentoBox()) === ethers.constants.AddressZero) {
          // Get a legacy route
          const rewardLegacyPath = [rewardToken, want, await strategy.native()];
          rewardToNativeRoute = [encodeRouteStep(true, rewardLegacyPath)];
        } else {
          // Get a trident route
          const rewardTridentPath = [
            [
              want, // pool
              ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "bool"],
                [rewardToken, strategy.address, true]
              ), // data
            ],
          ];
          rewardToNativeRoute = [encodeRouteStep(false, undefined, rewardTridentPath)];
        }
        const rewardToNativeRouteEncoded = ethers.utils.defaultAbiCoder.encode(["bytes[]"], [rewardToNativeRoute]);
        return rewardToNativeRouteEncoded;
      };

      // Add new reward
      const newRewardToken = await strategy.want(); // Any token address that is not an existing reward token on the strategy
      const newRewardToNativeRouteEncoded = await getToNativeRoute(newRewardToken);

      const rewardsBeforeAdd: string[] = await strategy.getActiveRewardsTokens();
      await strategy
        .connect(strategist)
        .addToNativeRoute(newRewardToNativeRouteEncoded);
      const rewardsAfterAdd: string[] = await strategy.getActiveRewardsTokens();

      expect(rewardsAfterAdd.length).to.be.eq(rewardsBeforeAdd.length + 1, "Adding reward failed");

      // Update reward route
      const rewardToken = await strategy.sushi();
      const rewardToNativeRouteEncoded = await getToNativeRoute(rewardToken);
      await strategy
        .connect(strategist)
        .addToNativeRoute(rewardToNativeRouteEncoded);
      const rewardsAfterUpdate: string[] = await strategy.getActiveRewardsTokens();

      expect(rewardsAfterUpdate.length).to.be.eq(
        rewardsAfterAdd.length,
        "Updating reward path results in redundance in activeRewardsTokens"
      );

      // Remove a reward token
      await strategy.connect(strategist).deactivateReward(rewardToken);
      const rewardsAfterRemove: string[] = await strategy.getActiveRewardsTokens();

      expect(rewardsAfterRemove.length).to.be.eq(rewardsAfterUpdate.length - 1, "Deactivating reward failed");
    });
  });
};

// Helpers
const getWantFor = async (signer: SignerWithAddress, strategy: Contract) => {
  const legacyRouterAbi = [
    "function addLiquidity(address tokenA,address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin,address to,uint256 deadline) returns (uint256 amountA,uint256 amountB,uint256 liquidity)",
    "function swapExactTokensForTokens(uint256 amountIn,uint256 amountOutMin,address[] path,address to,uint256 deadline) returns (uint256[] amounts)",
  ];
  const tridentRouterAbi = [
    "function addLiquidity(tuple(address token, bool native, uint256 amount)[] tokenInput, address pool, uint256 minLiquidity, bytes data) payable returns(uint256)",
    "function exactInputWithNativeToken(tuple(address tokenIn, uint256 amountIn, uint256 amountOutMinimum, tuple(address pool, bytes data)[])) payable returns(uint256 amountOut)",
  ];
  const bentoAbi = [
    "function setMasterContractApproval(address user,address masterContract,bool approved,uint8 v,bytes32 r,bytes32 s)",
  ];
  const legacyRouterAddr = await strategy.sushiRouter();
  const tridentRouterAddr = await strategy.tridentRouter();
  const bentoAddr = await strategy.bentoBox();
  const bentoBox = await ethers.getContractAt(bentoAbi, bentoAddr);
  const legacyRouter = await ethers.getContractAt(legacyRouterAbi, legacyRouterAddr);
  const tridentRouter = await ethers.getContractAt(tridentRouterAbi, tridentRouterAddr);
  const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
  const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
  const native = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.native());
  const isBentoPool = await strategy.isBentoPool();

  if (tridentRouter.address !== ethers.constants.AddressZero) {
    await bentoBox
      .connect(signer)
      .setMasterContractApproval(
        signer.address,
        tridentRouter.address,
        true,
        0,
        ethers.constants.HashZero,
        ethers.constants.HashZero
      );
  }

  const nativeBal: BigNumber = await native.balanceOf(signer.address);
  if (nativeBal.isZero()) throw "Signer have 0 native balance";

  type LegacyPathStep = string;
  type TridentPathStep = {pool: string; data: string};
  interface RouteStep {
    isLegacy: boolean;
    legacyPath: LegacyPathStep[];
    tridentPath: TridentPathStep[];
  }
  const token0Routes: RouteStep[] = [];
  const token0RoutesLength: number = await strategy
    .getToTokenRouteLength(token0.address)
    .then((x: BigNumber) => x.toNumber());
  for (let i = 0; i < token0RoutesLength; i++) {
    const {isLegacy, legacyPath, tridentPath} = await strategy.getToTokenRoute(token0.address, i);
    const route0: RouteStep = {isLegacy, legacyPath, tridentPath};
    token0Routes.push(route0);
  }

  const token1Routes: RouteStep[] = [];
  const token1RoutesLength: number = await strategy
    .getToTokenRouteLength(token1.address)
    .then((x: BigNumber) => x.toNumber());
  for (let i = 0; i < token1RoutesLength; i++) {
    const {isLegacy, legacyPath, tridentPath} = await strategy.getToTokenRoute(token1.address, i);
    const route1: RouteStep = {isLegacy, legacyPath, tridentPath};
    token1Routes.push(route1);
  }

  const deadline = Math.ceil(Date.now() / 1000) + 300;

  // Swap to token0
  let swapAmount: BigNumber = nativeBal.div(2);
  for (let i = 0; i < token0Routes.length; i++) {
    const isLegacy = token0Routes[i].isLegacy;
    if (isLegacy) {
      const route = token0Routes[i].legacyPath;
      const tokenInContract = await getContractAt("src/lib/erc20.sol:ERC20", route[0]);
      await tokenInContract.connect(signer).approve(legacyRouter.address, ethers.constants.MaxUint256);
      const amountsOut = await legacyRouter
        .connect(signer)
        .callStatic.swapExactTokensForTokens(swapAmount, 1, route, signer.address, deadline);
      await legacyRouter.connect(signer).swapExactTokensForTokens(swapAmount, 1, route, signer.address, deadline);
      swapAmount = amountsOut[amountsOut.length-1];
    } else {
      const strategyRoute = token0Routes[i].tridentPath;
      const [tokenIn] = ethers.utils.defaultAbiCoder.decode(["address", "address", "bool"], strategyRoute[0].data);
      const tokenInContract = await getContractAt("src/lib/erc20.sol:ERC20", tokenIn);
      await tokenInContract.connect(signer).approve(bentoBox.address, ethers.constants.MaxUint256);

      const userRoute = strategyRoute.map((r, idx) => {
        const pool = r.pool;
        const [tokenIn, receiver, unwrapBento] = ethers.utils.defaultAbiCoder.decode(
          ["address", "address", "bool"],
          r.data
        );
        const data = ethers.utils.defaultAbiCoder.encode(
          ["address", "address", "bool"],
          [tokenIn, idx === strategyRoute.length - 1 ? signer.address : receiver, unwrapBento]
        );
        return {pool, data};
      });
      const exactInputParams = [tokenInContract.address, swapAmount, 1, userRoute];
      const amountOut = await tridentRouter.connect(signer).callStatic.exactInputWithNativeToken(exactInputParams);
      await tridentRouter.connect(signer).exactInputWithNativeToken(exactInputParams);
      swapAmount = amountOut;
    }
  }

  // Swap to token1
  swapAmount = nativeBal.div(2);
  for (let i = 0; i < token1Routes.length; i++) {
    const isLegacy = token1Routes[i].isLegacy;
    if (isLegacy) {
      const route = token1Routes[i].legacyPath;
      const tokenInContract = await getContractAt("src/lib/erc20.sol:ERC20", route[0]);
      await tokenInContract.connect(signer).approve(legacyRouter.address, ethers.constants.MaxUint256);
      const amountsOut: BigNumber[] = await legacyRouter
        .connect(signer)
        .callStatic.swapExactTokensForTokens(swapAmount, 1, route, signer.address, deadline);
      await legacyRouter.connect(signer).swapExactTokensForTokens(swapAmount, 1, route, signer.address, deadline);
      swapAmount = amountsOut[amountsOut.length-1];
    } else {
      const strategyRoute = token1Routes[i].tridentPath;
      const [tokenIn] = ethers.utils.defaultAbiCoder.decode(["address", "address", "bool"], strategyRoute[0].data);
      const tokenInContract = await getContractAt("src/lib/erc20.sol:ERC20", tokenIn);
      await tokenInContract.connect(signer).approve(bentoBox.address, ethers.constants.MaxUint256);

      const userRoute = strategyRoute.map((r, idx) => {
        const pool = r.pool;
        const [tokenIn, receiver, unwrapBento] = ethers.utils.defaultAbiCoder.decode(
          ["address", "address", "bool"],
          r.data
        );
        const data = ethers.utils.defaultAbiCoder.encode(
          ["address", "address", "bool"],
          [tokenIn, idx === strategyRoute.length - 1 ? signer.address : receiver, unwrapBento]
        );
        return {pool, data};
      });

      const exactInputParams = [tokenInContract.address, swapAmount, 1, userRoute];

      const amountOut = await tridentRouter.connect(signer).callStatic.exactInputWithNativeToken(exactInputParams);
      await tridentRouter.connect(signer).exactInputWithNativeToken(exactInputParams);
      swapAmount = amountOut;
    }
  }

  const token0Bal = await token0.balanceOf(signer.address);
  const token1Bal = await token1.balanceOf(signer.address);

  if (isBentoPool) {
    const tokenInput = [
      [token0.address, true, token0Bal],
      [token1.address, true, token1Bal],
    ];
    const data = ethers.utils.defaultAbiCoder.encode(["address"], [signer.address]);
    await token0.connect(signer).approve(bentoBox.address, ethers.constants.MaxUint256);
    await token1.connect(signer).approve(bentoBox.address, ethers.constants.MaxUint256);
    await tridentRouter.connect(signer).addLiquidity(tokenInput, await strategy.want(), 1, data);
  } else {
    await token0.connect(signer).approve(legacyRouter.address, ethers.constants.MaxUint256);
    await token1.connect(signer).approve(legacyRouter.address, ethers.constants.MaxUint256);
    await legacyRouter
      .connect(signer)
      .addLiquidity(token0.address, token1.address, token0Bal, token1Bal, 0, 0, signer.address, deadline);
  }
};
