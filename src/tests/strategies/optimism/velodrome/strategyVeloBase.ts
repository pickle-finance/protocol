import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";
import { expect, increaseTime, getContractAt } from "../../../utils/testHelper";
import { setup } from "../../../utils/setupHelper";
import { NULL_ADDRESS } from "../../../utils/constants";
import { BigNumber, Contract } from "ethers";
import { loadFixture, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export const doTestBehaviorBase = (
  strategyName: string,
  days = 15,
) => {
  const shortName = strategyName.substring(strategyName.lastIndexOf(":") + 2);
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
        treasury,
      );

      const want = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.want());
      const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
      const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
      const native = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.native());

      // Get some want tokens into Alice wallet
      await setBalance(alice.address, ethers.utils.parseEther("1.1"));
      const wNativeDepositAbi = ["function deposit() payable", "function approve(address,uint256) returns(bool)"];
      const wNativeDeposit = await ethers.getContractAt(wNativeDepositAbi, native.address);
      await wNativeDeposit.connect(alice).deposit({ value: ethers.utils.parseEther("1") });
      await getWantFor(alice, strategy);
      const wantBalance:BigNumber = await want.balanceOf(alice.address);
      expect(wantBalance.isZero()).to.be.eq(false, "Alice failed to get some want tokens!");

      return { strategy, jar, controller, governance, treasury, timelock, devfund, strategist, alice, want, native, token0, token1 };
    };

    it("Should set the timelock correctly", async () => {
      const { strategy, timelock } = await loadFixture(initialSetupFixture);
      expect(await strategy.timelock()).to.be.eq(
        timelock.address,
        "timelock is incorrect"
      );
      await strategy.setTimelock(NULL_ADDRESS);
      expect(await strategy.timelock()).to.be.eq(
        NULL_ADDRESS,
        "timelock is incorrect"
      );
    });
    const getWantFor = async (signer: SignerWithAddress, strategy: Contract) => {
      const routerAbi = [
        "function addLiquidity(address tokenA, address tokenB, bool stable, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline)",
        // "function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, tuple(address from, address to, bool stable)[] routes, address to, uint256 deadline) returns (uint256[] amounts)",
        {"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"components":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"bool","name":"stable","type":"bool"}],"internalType":"struct Router.route[]","name":"routes","type":"tuple[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},
      ];
      const routerAddr = "0x9c12939390052919aF3155f41Bf4160Fd3666A6f";
      const router = await ethers.getContractAt(routerAbi, routerAddr);
      const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
      const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
      const native = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.native());
      const isStable = await strategy.isStablePool();

      const nativeBal: BigNumber = await native.balanceOf(signer.address);
      if (nativeBal.isZero()) throw "Signer have 0 native balance";

      interface Route { from: string; to: string; stable: boolean; };
      const token0Routes: Route[] = [];
      const token1Routes: Route[] = [];
      for (let i = 0; i < 5; i++) {
        if (token0.address === native.address) break;
        const route0: Route = await strategy.nativeToTokenRoutes(token0.address, i);
        token0Routes.push(route0);
        if (route0.to === token0.address) break;
      }
      for (let i = 0; i < 5; i++) {
        if (token1.address === native.address) break;
        const route1: Route = await strategy.nativeToTokenRoutes(token1.address, i);
        token1Routes.push(route1);
        if (route1.to === token1.address) break;
      }

      const deadline = Math.ceil(Date.now() / 1000) + 300;

      await native.connect(signer).approve(router.address, ethers.constants.MaxUint256);
      token0.address !== native.address && await router.connect(signer).swapExactTokensForTokens(nativeBal.div(2), 0, token0Routes, signer.address, deadline);
      token1.address !== native.address && await router.connect(signer).swapExactTokensForTokens(nativeBal.div(2), 0, token1Routes, signer.address, deadline);

      const token0Bal = await token0.balanceOf(signer.address);
      const token1Bal = await token1.balanceOf(signer.address);
      await token0.connect(signer).approve(router.address, ethers.constants.MaxUint256);
      await token1.connect(signer).approve(router.address, ethers.constants.MaxUint256);
      await router.connect(signer).addLiquidity(token0.address, token1.address, isStable, token0Bal, token1Bal, 0, 0, signer.address, deadline);
    }

    it("Should withdraw correctly", async () => {
      const { want, alice, jar: pickleJar, strategy, controller } = await loadFixture(initialSetupFixture);
      const _want: BigNumber = await want.balanceOf(alice.address);
      await want.connect(alice).approve(pickleJar.address, _want);
      await pickleJar.connect(alice).deposit(_want);
      console.log(
        "Alice pTokenBalance after deposit: %s\n",
        (await pickleJar.balanceOf(alice.address)).toString()
      );
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * days); //travel days into the future

      console.log(
        "\nRatio before harvest: ",
        (await pickleJar.getRatio()).toString()
      );

      await strategy.harvest();

      console.log(
        "Ratio after harvest: %s",
        (await pickleJar.getRatio()).toString()
      );

      let _before: BigNumber = await want.balanceOf(pickleJar.address);
      console.log(
        "\nPicklejar balance before controller withdrawal: ",
        _before.toString()
      );

      await controller.withdrawAll(want.address);

      let _after: BigNumber = await want.balanceOf(pickleJar.address);
      console.log(
        "Picklejar balance after controller withdrawal: ",
        _after.toString()
      );

      expect(_after).to.be.gt(_before, "controller withdrawAll failed");

      _before = await want.balanceOf(alice.address);
      console.log(
        "\nAlice balance before picklejar withdrawal: ",
        _before.toString()
      );

      await pickleJar.withdrawAll();

      _after = await want.balanceOf(alice.address);
      console.log(
        "Alice balance after picklejar withdrawal: ",
        _after.toString()
      );

      expect(_after).to.be.gt(_before, "picklejar withdrawAll failed");
      expect(_after).to.be.gt(_want, "no interest earned");
    });

    it("Should harvest correctly", async () => {
      const { want, alice, jar: pickleJar, strategy, native, treasury, devfund } = await loadFixture(initialSetupFixture);
      const _want: BigNumber = await want.balanceOf(alice.address);
      await want.connect(alice).approve(pickleJar.address, _want);
      await pickleJar.connect(alice).deposit(_want);
      console.log(
        "Alice pTokenBalance after deposit: %s\n",
        (await pickleJar.balanceOf(alice.address)).toString()
      );
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * days); //travel days into the future

      const pendingRewards: [string[], BigNumber[]] =
        await strategy.getHarvestable();
      const _before: BigNumber = await pickleJar.balance();
      let _treasuryBefore: BigNumber = await native.balanceOf(treasury.address);

      console.log("Rewards harvestable amounts:");
      pendingRewards[0].forEach((addr, i) => {
        console.log(`\t${addr}: ${pendingRewards[1][i].toString()}`);
      });
      console.log("Picklejar balance before harvest: ", _before.toString());
      console.log(
        "💸 Treasury reward token balance before harvest: ",
        _treasuryBefore.toString()
      );
      console.log(
        "\nRatio before harvest: ",
        (await pickleJar.getRatio()).toString()
      );

      await strategy.harvest();

      const _after: BigNumber = await pickleJar.balance();
      let _treasuryAfter: BigNumber = await native.balanceOf(treasury.address);
      console.log(
        "Ratio after harvest: ",
        (await pickleJar.getRatio()).toString()
      );
      console.log("\nPicklejar balance after harvest: ", _after.toString());
      console.log(
        "💸 Treasury reward token balance after harvest: ",
        _treasuryAfter.toString()
      );

      //performance fee is given
      const rewardsEarned = _treasuryAfter.sub(_treasuryBefore);
      console.log(
        "\nPerformance fee earned by treasury: ",
        rewardsEarned.toString()
      );

      expect(rewardsEarned).to.be.gt(0, "no performance fee taken");

      //withdraw
      const _devBefore: BigNumber = await want.balanceOf(devfund.address);
      _treasuryBefore = await want.balanceOf(treasury.address);
      console.log(
        "\n👨‍🌾 Dev balance before picklejar withdrawal: ",
        _devBefore.toString()
      );
      console.log(
        "💸 Treasury balance before picklejar withdrawal: ",
        _treasuryBefore.toString()
      );

      await pickleJar.withdrawAll();

      const _devAfter: BigNumber = await want.balanceOf(devfund.address);
      _treasuryAfter = await want.balanceOf(treasury.address);
      console.log(
        "\n👨‍🌾 Dev balance after picklejar withdrawal: ",
        _devAfter.toString()
      );
      console.log(
        "💸 Treasury balance after picklejar withdrawal: ",
        _treasuryAfter.toString()
      );

      //0% goes to dev
      const _devFund = _devAfter.sub(_devBefore);
      expect(_devFund).to.be.eq(0, "dev've stolen money!!!!!");

      //0% goes to treasury
      const _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
      expect(_treasuryFund).to.be.eq(0, "treasury've stolen money!!!!");
    });

    it("Should perform multiple deposits and withdrawals correctly", async () => {
      const { want, alice, jar: pickleJar, strategist } = await loadFixture(initialSetupFixture);
      const _wantHalved: BigNumber = (await want.balanceOf(alice.address)).div(
        2
      );
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
      let _strategistBalanceAfter: BigNumber = await want.balanceOf(
        strategist.address
      );
      console.log(
        "\nAlice balance after half withdrawal: %s\n",
        _aliceBalanceAfter.toString()
      );
      console.log(
        "\nStrategist balance after half withdrawal: %s\n",
        _strategistBalanceAfter.toString()
      );

      expect(_aliceBalanceAfter).to.be.approximately(
        _wantHalved.div(2),
        1,
        "Alice withdrawal amount incorrect"
      );

      expect(_strategistBalanceAfter).to.be.approximately(
        _wantHalved,
        1,
        "Strategist withdrawal amount incorrect"
      );

      // Alice withdraws remainder

      await pickleJar.connect(alice).withdrawAll();
      _aliceBalanceAfter = await want.balanceOf(alice.address);
      console.log(
        "\nAlice balance after full withdrawal: %s\n",
        _aliceBalanceAfter.toString()
      );
      expect(_aliceBalanceAfter).to.be.approximately(
        _wantHalved,
        1,
        "Alice withdrawal amount incorrect"
      );
    });

    it("should add and remove rewards correctly", async () => {
      const { alice, strategy, native } = await loadFixture(initialSetupFixture);
      const routify = (from: string, to: string, isStable: boolean) => {
        return { from: from, to: to, stable: isStable };
      };

      // Addresses
      const notRewardToken = await strategy.want(); // Any token address that is not a reward token
      const reward_addr = await strategy.velo();

      // A valid toNative route for a currently registered reward token (can be the same as the registered one)
      // it should not add to activeRewardsTokens array, only replace the existing array element!
      const validToNativeRoute = [routify(reward_addr, notRewardToken, false)];

      // Arbitrary new reward route
      const arbNewRoute = [routify(notRewardToken, native.address, false)];

      // Add reward tokens
      const rewardsBeforeAdd: string[] =
        await strategy.getActiveRewardsTokens();

      await strategy.connect(alice).addToNativeRoute(validToNativeRoute);
      await strategy.connect(alice).addToNativeRoute(arbNewRoute);
      const rewardsAfterAdd: string[] = await strategy.getActiveRewardsTokens();

      expect(rewardsAfterAdd.length).to.be.eq(
        rewardsBeforeAdd.length + 1,
        "Adding reward failed"
      );
      expect(
        rewardsAfterAdd.filter(
          (z) => z.toLowerCase() === reward_addr.toLowerCase()
        ).length
      ).to.be.eq(
        1,
        "Updating reward path results in redundance in activeRewardsTokens"
      );

      // Remove a reward token
      await strategy.connect(alice).deactivateReward(reward_addr);
      const rewardsAfterRemove: string[] =
        await strategy.getActiveRewardsTokens();

      expect(rewardsAfterRemove.length).to.be.eq(
        rewardsAfterAdd.length - 1,
        "Deactivating reward failed"
      );
    });
  });
};
