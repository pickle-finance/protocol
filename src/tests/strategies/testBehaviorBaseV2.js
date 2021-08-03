const {expect, increaseTime, getContractAt} = require("../utils/testHelper");
const {setup} = require("../utils/setupHelper");
const {NULL_ADDRESS} = require("../utils/constants");

const doTestBehaviorBaseV2 = (strategyName, want_addr) => {
  let alice, want;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  describe(`${strategyName} common behavior tests v2`, () => {
    before("Setup contracts", async () => {
      [alice, devfund, treasury] = await hre.ethers.getSigners();
      governance = alice;
      strategist = alice;
      timelock = alice;

      want = await getContractAt("ERC20", want_addr);

      [controller, strategy, pickleJar] = await setup(
        strategyName,
        want,
        governance,
        strategist,
        timelock,
        devfund,
        treasury
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

      await increaseTime(60 * 60 * 24 * 15); //travel 15 days

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

    it("Should multiple harvests correctly", async () => {
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      // First harvest
      console.log("\n- The first harvest, travel 15 days -");

      await increaseTime(60 * 60 * 24 * 15); //travel 15 days
      const _before1 = await pickleJar.balance();
      let _treasuryBefore1 = await want.balanceOf(treasury.address);

      console.log("Picklejar balance before the first harvest: ", _before1.toString());
      console.log("💸 Treasury balance before the first harvest: ", _treasuryBefore1.toString());
      console.log("\nRatio before the first harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      const _after1 = await pickleJar.balance();
      let _treasuryAfter1 = await want.balanceOf(treasury.address);
      console.log("Ratio after the first harvest: ", (await pickleJar.getRatio()).toString());
      console.log("\nPicklejar balance after the first harvest: ", _after1.toString());
      console.log("💸 Treasury balance after the first harvest: ", _treasuryAfter1.toString());

      //20% performance fee is given
      const earned1 = _after1.sub(_before1).mul(1000).div(800);
      const earnedRewards1 = earned1.mul(200).div(1000);
      const actualRewardsEarned1 = _treasuryAfter1.sub(_treasuryBefore1);
      console.log("\nActual reward earned by treasury from the first harvest: ", actualRewardsEarned1.toString());

      expect(earnedRewards1).to.be.eqApprox(actualRewardsEarned1, "20% performance fee is not given");

      // Second harvest
      console.log("\n- The second harvest, travel 3 days -");

      await increaseTime(60 * 60 * 24 * 3); //travel 3 days
      const _before2 = await pickleJar.balance();
      let _treasuryBefore2 = await want.balanceOf(treasury.address);

      console.log("Picklejar balance before the second harvest: ", _before2.toString());
      console.log("💸 Treasury balance before the second harvest: ", _treasuryBefore2.toString());
      console.log("\nRatio before the second harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      const _after2 = await pickleJar.balance();
      let _treasuryAfter2 = await want.balanceOf(treasury.address);
      console.log("Ratio after the second harvest: ", (await pickleJar.getRatio()).toString());
      console.log("\nPicklejar balance after the second harvest: ", _after2.toString());
      console.log("💸 Treasury balance after the second harvest: ", _treasuryAfter2.toString());

      //20% performance fee is given
      const earned2 = _after2.sub(_before2).mul(1000).div(800);
      const earnedRewards2 = earned2.mul(200).div(1000);
      const actualRewardsEarned2 = _treasuryAfter2.sub(_treasuryBefore2);
      console.log("\nActual reward earned by treasury from the second harvest: ", actualRewardsEarned2.toString());

      expect(earnedRewards2).to.be.eqApprox(actualRewardsEarned2, "20% performance fee is not given");

      // Third harvest
      console.log("\n- The third harvest, travel 7 days -");

      await increaseTime(60 * 60 * 24 * 7); //travel 7 days
      const _before3 = await pickleJar.balance();
      let _treasuryBefore3 = await want.balanceOf(treasury.address);

      console.log("Picklejar balance before the third harvest: ", _before3.toString());
      console.log("💸 Treasury balance before the third harvest: ", _treasuryBefore3.toString());
      console.log("\nRatio before the third harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      const _after3 = await pickleJar.balance();
      let _treasuryAfter3 = await want.balanceOf(treasury.address);
      console.log("Ratio after the third harvest: ", (await pickleJar.getRatio()).toString());
      console.log("\nPicklejar balance after the third harvest: ", _after3.toString());
      console.log("💸 Treasury balance after the third harvest: ", _treasuryAfter3.toString());

      //20% performance fee is given
      const earned3 = _after3.sub(_before3).mul(1000).div(800);
      const earnedRewards3 = earned3.mul(200).div(1000);
      const actualRewardsEarned3 = _treasuryAfter3.sub(_treasuryBefore3);
      console.log("\nActual reward earned by treasury from the third harvest: ", actualRewardsEarned3.toString());

      expect(earnedRewards3).to.be.eqApprox(actualRewardsEarned3, "20% performance fee is not given");

      //withdraw
      const _devBefore = await want.balanceOf(devfund.address);
      let _treasuryBefore = await want.balanceOf(treasury.address);
      console.log("\n👨‍🌾 Dev balance before picklejar withdrawal: ", _devBefore.toString());
      console.log("💸 Treasury balance before picklejar withdrawal: ", _treasuryBefore.toString());

      await pickleJar.withdrawAll();

      const _devAfter = await want.balanceOf(devfund.address);
      let _treasuryAfter = await want.balanceOf(treasury.address);
      console.log("\n👨‍🌾 Dev balance after picklejar withdrawal: ", _devAfter.toString());
      console.log("💸 Treasury balance after picklejar withdrawal: ", _treasuryAfter.toString());

      //0% goes to dev
      const _devFund = _devAfter.sub(_devBefore);
      expect(_devFund).to.be.eq(0, "dev've stolen money!!!!!");

      //0% goes to treasury
      const _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
      expect(_treasuryFund).to.be.eq(0, "treasury've stolen money!!!!");
    });

    beforeEach(async () => {
      preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};

module.exports = {doTestBehaviorBaseV2};
