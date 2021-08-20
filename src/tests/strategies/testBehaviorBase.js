const {expect, increaseTime, getContractAt} = require("../utils/testHelper");
const {setup} = require("../utils/setupHelper");
const {NULL_ADDRESS} = require("../utils/constants");

const doTestBehaviorBase = (strategyName, want_addr, isPolygon = false) => {
  let alice, want;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  describe(`${strategyName} common behavior tests`, () => {
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

    it("Should harvest correctly", async () => {
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 15); //travel 15 days
      const _before = await pickleJar.balance();
      let _treasuryBefore = await want.balanceOf(treasury.address);

      console.log("Picklejar balance before harvest: ", _before.toString());
      console.log("💸 Treasury balance before harvest: ", _treasuryBefore.toString());
      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.harvest();

      const _after = await pickleJar.balance();
      let _treasuryAfter = await want.balanceOf(treasury.address);
      console.log("Ratio after harvest: ", (await pickleJar.getRatio()).toString());
      console.log("\nPicklejar balance after harvest: ", _after.toString());
      console.log("💸 Treasury balance after harvest: ", _treasuryAfter.toString());

      //20% performance fee is given
      const earned = _after.sub(_before).mul(1000).div(800);
      const earnedRewards = earned.mul(200).div(1000);
      const actualRewardsEarned = _treasuryAfter.sub(_treasuryBefore);
      console.log("\nActual reward earned by treasury: ", actualRewardsEarned.toString());

      expect(earnedRewards).to.be.eqApprox(actualRewardsEarned, "20% performance fee is not given");

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

    beforeEach(async () => {
      preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};

module.exports = {doTestBehaviorBase};
