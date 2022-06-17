const {expect, increaseTime, getContractAt, increaseBlock} = require("../../utils/testHelper");
const {setup} = require("../../utils/setupHelper");
const {NULL_ADDRESS} = require("../../utils/constants");
const {BigNumber: BN} = require("ethers");

const doTestBehaviorBase = (strategyName, want_addr, reward_addr, bIncreaseBlock = false, isPolygon = false) => {
  let alice, want, reward;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  describe(`${strategyName} common behavior tests`, () => {
    before("Setup contracts", async () => {
      [alice, devfund, treasury] = await hre.ethers.getSigners();
      governance = alice;
      strategist = devfund;
      timelock = alice;

      want = await getContractAt("ERC20", want_addr);

      reward = await getContractAt("ERC20", reward_addr);

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
    });

    it("Should set the timelock correctly", async () => {
      expect(await strategy.timelock()).to.be.eq(timelock.address, "timelock is incorrect");
      await strategy.setTimelock(NULL_ADDRESS);
      expect(await strategy.timelock()).to.be.eq(NULL_ADDRESS, "timelock is incorrect");
    });

    it("Should withdraw correctly", async () => {
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 5); //travel 5 days
      if (bIncreaseBlock) {
        await increaseBlock((60 * 60 * 24 * 5) / 5); //roughly 5 days
      }

      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      console.log("Ratio after harvest: %s", (await pickleJar.getRatio()).toString());

      let _before = await want.balanceOf(pickleJar.address);
      console.log("\nPicklejar balance before controller withdrawal: ", _before.toString());

      await controller.withdrawAll(want.address);

      let _after = await want.balanceOf(pickleJar.address);
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
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 5); //travel 5 days
      if (bIncreaseBlock) {
        await increaseBlock((60 * 60 * 24 * 5) / 5); //roughly 5 days
      }
      const pendingRewards = await strategy.getHarvestable();
      const _before = await pickleJar.balance();
      let _treasuryBefore = await reward.balanceOf(treasury.address);

      console.log("Rewards harvestable amounts:");
      pendingRewards[0].forEach((addr, i) => {
        console.log(`\t${addr}: ${pendingRewards[1][i].toString()}`);
      });
      console.log("Picklejar balance before harvest: ", _before.toString());
      console.log("💸 Treasury reward token balance before harvest: ", _treasuryBefore.toString());
      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      const _after = await pickleJar.balance();
      let _treasuryAfter = await reward.balanceOf(treasury.address);
      console.log("Ratio after harvest: ", (await pickleJar.getRatio()).toString());
      console.log("\nPicklejar balance after harvest: ", _after.toString());
      console.log("💸 Treasury reward token balance after harvest: ", _treasuryAfter.toString());

      //performance fee is given
      const rewardsEarned = _treasuryAfter.sub(_treasuryBefore);
      console.log("\nPerformance fee earned by treasury: ", rewardsEarned.toString());

      expect(rewardsEarned).to.be.gt(0, "no performance fee taken");

      //withdraw
      const _devBefore = await want.balanceOf(devfund.address);
      _treasuryBefore = await want.balanceOf(treasury.address);
      console.log("\n👨‍🌾 Dev balance before picklejar withdrawal: ", _devBefore.toString());
      console.log("💸 Treasury balance before picklejar withdrawal: ", _treasuryBefore.toString());

      await pickleJar.withdrawAll();

      const _devAfter = await want.balanceOf(devfund.address);
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
      const _wantHalved = (await want.balanceOf(alice.address)).div(2);
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

      let _aliceBalanceAfter = await want.balanceOf(alice.address);
      let _strategistBalanceAfter = await want.balanceOf(strategist.address);
      console.log("\nAlice balance after half withdrawal: %s\n", _aliceBalanceAfter.toString());
      console.log("\nStrategist balance after half withdrawal: %s\n", _strategistBalanceAfter.toString());

      expect(_aliceBalanceAfter).to.be.eqApprox(_wantHalved.div(2), "Alice withdrawal amount incorrect");

      expect(_strategistBalanceAfter).to.be.eqApprox(_wantHalved, "Strategist withdrawal amount incorrect");

      // Alice withdraws remainder

      await pickleJar.connect(alice).withdrawAll();
      _aliceBalanceAfter = await want.balanceOf(alice.address);
      console.log("\nAlice balance after full withdrawal: %s\n", _aliceBalanceAfter.toString());
      expect(_aliceBalanceAfter).to.be.eqApprox(_wantHalved, "Alice withdrawal amount incorrect");
    });

    it("should add and remove rewards correctly", async () => {
      const rewardsBeforeAdd = await strategy.getActiveRewardsTokens();

      await strategy
        .connect(alice)
        .addToNativeRoute(["0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d", "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d"]);
      const rewardsAfterAdd = await strategy.getActiveRewardsTokens();

      expect(rewardsAfterAdd.length).to.be.eq(rewardsBeforeAdd.length + 1, "Adding reward failed");

      await strategy.connect(alice).deactivateReward("0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d");
      const rewardsAfterRemove = await strategy.getActiveRewardsTokens();

      expect(rewardsAfterRemove.length).to.be.eq(rewardsAfterAdd.length - 1, "Deactivating reward failed");
    });

    beforeEach(async () => {
      preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};

module.exports = {doTestBehaviorBase};
