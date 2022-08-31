import "@nomicfoundation/hardhat-toolbox";
import { ethers, network } from "hardhat";
import {
  expect,
  increaseTime,
  getContractAt,
  increaseBlock,
} from "../../../utils/testHelper";
import { setup } from "../../../utils/setupHelper";
import { NULL_ADDRESS } from "../../../utils/constants";
import { BigNumber, Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export const doTestBehaviorBase = (
  strategyName: string,
  want_addr: string,
  reward_addr: string,
  days = 15,
  bIncreaseBlock = false,
  isPolygon = false,
  bloctime = 5
) => {
  let alice: SignerWithAddress, want: Contract, native: Contract;
  let strategy: Contract, pickleJar: Contract, controller: Contract;
  let governance: SignerWithAddress,
    strategist: SignerWithAddress,
    devfund: SignerWithAddress,
    treasury: SignerWithAddress,
    timelock: SignerWithAddress;
  let preTestSnapshotID: any;

  describe(`${strategyName} common behavior tests`, () => {
    before("Setup contracts", async () => {
      [alice, devfund, treasury] = await ethers.getSigners();
      governance = alice;
      strategist = devfund;
      timelock = alice;

      want = await getContractAt("src/lib/erc20.sol:ERC20", want_addr);

      [controller, strategy, pickleJar] = await setup(
        strategyName,
        want,
        governance,
        strategist,
        timelock,
        devfund,
        treasury,
        isPolygon
      );

      const nativeAddr = await strategy.native();
      native = await getContractAt("src/lib/erc20.sol:ERC20", nativeAddr);
    });

    it("Should set the timelock correctly", async () => {
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

    it("Should withdraw correctly", async () => {
      const _want: BigNumber = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log(
        "Alice pTokenBalance after deposit: %s\n",
        (await pickleJar.balanceOf(alice.address)).toString()
      );
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * days); //travel days into the future
      if (bIncreaseBlock) {
        await increaseBlock((60 * 60 * 24 * days) / bloctime); //roughly days
      }

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
      const _want: BigNumber = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log(
        "Alice pTokenBalance after deposit: %s\n",
        (await pickleJar.balanceOf(alice.address)).toString()
      );
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * days); //travel days into the future
      if (bIncreaseBlock) {
        await increaseBlock((60 * 60 * 24 * days) / bloctime); //roughly days
      }
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
      const routify = (from: string, to: string, isStable: boolean) => {
        return { from: from, to: to, stable: isStable };
      };

      // Addresses
      const usdc = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";
      const notRewardToken = usdc; // Any token address that is not a reward token

      // A valid toNative route for a currently registered reward token (can be the same as the registered one)
      // it should not add to activeRewardsTokens array!
      const validToNativeRoute = [routify(reward_addr, native.address, false)];

      // Arbitrary new reward route, should increase activeRewardsTokens count
      const newToNativeRoute = [routify(notRewardToken, native.address, false)];

      // Invalid toNative route, adding this route should fail
      const invalidToNativeRoute = [routify(reward_addr, notRewardToken, false)];

      // Valid toToken route (doesn't have to be for an actual strategy token)
      const validToTokenRoute = [routify(native.address, notRewardToken, false)];

      // Invalid toToken route, adding this route should fail
      const invalidToTokenRoute = [routify(reward_addr, notRewardToken, false)];

      // Add reward tokens
      const rewardsBeforeAdd: string[] =
        await strategy.getActiveRewardsTokens();

      console.log("\nAdding valid toNative route...\n");
      await strategy.connect(alice).addToNativeRoute(validToNativeRoute);
      console.log("\nAdding new toNative route...\n");
      await strategy.connect(alice).addToNativeRoute(newToNativeRoute);
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

      // Add valid toToken route
      console.log("\nAdding toToken route...\n");
      await strategy.addToTokenRoute(validToTokenRoute);

      // Attempt to add invalid toNative route
      let callReverted = false;
      try {
        // This call should revert
        console.log("\nAttempting adding invalid toNative route...\n");
        await strategy.connect(alice).addToNativeRoute(invalidToNativeRoute);
      } catch (e) {
        callReverted = true;
      }
      expect(callReverted).to.be.eq(
        true,
        "Strategy accepts adding invalid toNative route"
      );

      // Attempt to add invalid toToken route
      callReverted = false;
      try {
        // This call should revert
        console.log("\nAttempting adding invalid toToken route...\n");
        await strategy.connect(alice).addToTokenRoute(invalidToTokenRoute);
      } catch (e) {
        callReverted = true;
      }
      expect(callReverted).to.be.eq(
        true,
        "Strategy accepts adding invalid toToken route"
      );

      // Remove a reward token
      console.log("\nDeactivating a reward...\n");
      await strategy.connect(alice).deactivateReward(reward_addr);
      const rewardsAfterRemove: string[] =
        await strategy.getActiveRewardsTokens();

      expect(rewardsAfterRemove.length).to.be.eq(
        rewardsAfterAdd.length - 1,
        "Deactivating reward failed"
      );
    });

    beforeEach(async () => {
      preTestSnapshotID = await network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};
