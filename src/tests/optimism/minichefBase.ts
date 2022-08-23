import "@nomicfoundation/hardhat-toolbox";
import { ethers, network } from "hardhat";
import {
  expect,
  increaseTime,
  getContractAt,
  increaseBlock,
  deployContract,
  toWei,
} from "../utils/testHelper";
import { getWantFromWhale, setup } from "../utils/setupHelper";
import { NULL_ADDRESS } from "../utils/constants";
import { BigNumber, Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export const doTestBehaviorBase = (
  pickleAddr: string,
  pickleWhale: string,
  pToken1Addr: string,
  pToken1Whale: string,
  pToken2Addr: string,
  pToken2Whale: string,
  reward_addr: string,
  days = 15,
  bIncreaseBlock = false,
  bloctime = 5
) => {
  let alice: SignerWithAddress, governance: SignerWithAddress;
  let minichefV2: Contract, pickle: Contract, pToken1: Contract, pToken2: Contract;
  let preTestSnapshotID: any;

  describe(`MiniChefV2 common behavior tests`, () => {
    before("Setup contracts", async () => {
      [alice, governance] = await ethers.getSigners();

      pickle = await getContractAt("src/lib/erc20.sol:ERC20", pickleAddr);
      pToken1 = await getContractAt("src/lib/erc20.sol:ERC20", pToken1Addr);
      pToken2 = await getContractAt("src/lib/erc20.sol:ERC20", pToken2Addr);

      minichefV2 = await deployContract(
        "src/polygon/minichefv2.sol:MiniChefV2",
        pickleAddr
      );
      await minichefV2.transferOwnership(governance.address, false, false);
      await minichefV2.connect(governance).claimOwnership();

      //TODO move up
      await getWantFromWhale(pickleAddr, toWei(100), governance, pickleWhale);
      await getWantFromWhale(pToken1Addr, toWei(100), alice, pToken1Whale);
      await getWantFromWhale(pToken2Addr, toWei(100), alice, pToken2Whale);

      // Set picklePerSecond
      const totalPickle:BigNumber = await pickle.balanceOf(governance.address);
      const daysInSeconds = BigNumber.from(days*24*60*60);
      const picklePerSecond = totalPickle.div(daysInSeconds);
      await pickle.connect(governance).transfer(minichefV2.address, totalPickle);
      await minichefV2.connect(governance).setPicklePerSecond(picklePerSecond);

      // Add pools
      await minichefV2.connect(governance).add(40, pToken1.address, ethers.constants.AddressZero);
      await minichefV2.connect(governance).add(60, pToken2.address, ethers.constants.AddressZero);
    });

    it("Should set the owner correctly", async () => {
      expect(await minichefV2.owner()).to.be.eq(
        governance.address,
        "owner is incorrect"
      );

      let renounceFailed = false;
      try {
        // This call should fail
        await minichefV2
          .connect(governance)
          .transferOwnership(NULL_ADDRESS, false, false);
      } catch (error) {
        renounceFailed = true;
      }
      expect(renounceFailed).to.be.eq(true, "timelock is incorrect");
    });

    it("Should deposit and withdraw correctly", async () => {

      // DEPOSIT
      const want = pToken1;
      const _want: BigNumber = await want.balanceOf(alice.address);
      console.log("Alice pTokenBalance before deposit: %s\n", _want.toString());
      console.log("MiniChefV2 pTokenBalance before deposit: %s\n", (await want.balanceOf(minichefV2.address)).toString());
      await want.approve(minichefV2.address, _want);
      await minichefV2.connect(alice).deposit(0,_want,alice.address);
      console.log(
        "Alice pTokenBalance after deposit: %s\n",
        (await want.balanceOf(alice.address)).toString()
      );
      const mc2BalAfter:BigNumber = await want.balanceOf(minichefV2.address);
      console.log("MiniChefV2 pTokenBalance after deposit: %s\n", mc2BalAfter.toString());
      expect(mc2BalAfter).to.be.eq(_want, "Deposit failed");

      // HARVEST
      await increaseTime(60 * 60 * 24 * days); //travel days into the future
      if (bIncreaseBlock) {
        await increaseBlock((60 * 60 * 24 * days) / bloctime); //roughly days
      }

      console.log("Alice PICKLE balance before harvest: %s", (await pickle.balanceOf(alice.address)).toString());

      await minichefV2.connect(alice).harvest(0, alice.address);

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

    it("should add and remove pools correctly", async () => {
      const routify = (from: string, to: string, isStable: boolean) => {
        return { from: from, to: to, stable: isStable };
      };

      // Addresses
      const usdc = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";
      const notRewardToken = usdc; // Any token address that is not a reward token

      // A valid toNative route for a currently registered reward token (can be the same as the registered one)
      // it should not add to activeRewardsTokens array!
      const validToNativeRoute = [routify(reward_addr, usdc, false)];

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

    beforeEach(async () => {
      preTestSnapshotID = await network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};
