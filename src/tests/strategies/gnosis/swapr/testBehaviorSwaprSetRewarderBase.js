const {expect, increaseTime, getContractAt, increaseBlock} = require("../../../utils/testHelper");
const {setup} = require("../../../utils/setupHelper");
const {NULL_ADDRESS} = require("../../../utils/constants");
const {BigNumber: BN, getDefaultProvider} = require("ethers");

const doTestBehaviorBase = (
  strategyName,
  want_addr,
  reward_addr,
  new_rewarder_addr,
  bIncreaseBlock = false,
  isPolygon = false
) => {
  let alice, want, reward;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  const setRewarder = async () => {
    const rewarderAddrBeforeSet = await strategy.rewarder();
    const rewarderBalanceBeforeSet = await strategy.balanceOfPool();
    console.log("Old Rewarder Address: ", rewarderAddrBeforeSet);

    await increaseTime(60 * 60 * 24 * 1); //travel 1 day
    if (bIncreaseBlock) {
      await increaseBlock((60 * 60 * 24 * 1) / 5); //roughly 1 day
    }

    await strategy.connect(alice).setRewarder(new_rewarder_addr);

    const rewarderAddrAfterSet = await strategy.rewarder();
    const rewarderBalanceAfterSet = await strategy.balanceOfPool();
    console.log("New Rewarder Address: ", rewarderAddrAfterSet);

    return rewarderBalanceBeforeSet.eq(rewarderBalanceAfterSet) && rewarderAddrBeforeSet != rewarderAddrAfterSet;
  };

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

    it("Should set new rewarder & harvest correctly", async () => {
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      expect(await setRewarder()).to.be.eq(true, "setRewarder failed!");

      await increaseTime(60 * 60 * 24 * 2); //travel 2 days
      if (bIncreaseBlock) {
        await increaseBlock((60 * 60 * 24 * 2) / 5); //roughly 2 days
      }
      const pendingRewards = await strategy.getHarvestable();
      const _before = await pickleJar.balance();
      let _treasuryBefore = await reward.balanceOf(treasury.address);

      console.log("Rewards harvestable amounts:");
      pendingRewards[0].forEach((addr, i) => {
        console.log(`${addr}: ${pendingRewards[1][i].toString()}`);
      });
      console.log("Picklejar balance before harvest: ", _before.toString());
      console.log("💸 Treasury reward token balance before harvest: ", _treasuryBefore.toString());
      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await strategy.connect(alice).claim();
      await strategy.connect(alice).setRewarder(new_rewarder_addr);
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

    beforeEach(async () => {
      preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};

module.exports = {doTestBehaviorBase};
