const {expect, increaseTime, getContractAt, deployContract, unlockAccount, toWei} = require("../utils/testHelper");
const {setup} = require("../utils/setupHelper");
const {NULL_ADDRESS} = require("../utils/constants");

const doTestMigrationBaseWithAddresses = (oldStrategyName, oldStrategyAddress, pickleJarAddress, newStrategyName, want_addr) => {
  let alice, want;
  let newStrategy, pickleJar, controller, oldStrategy, controllerStrategist;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  describe(`${oldStrategyName} at ${oldStrategyAddress} => ${newStrategyName} common migration tests`, () => {
    before("Setup contracts", async () => {
      [alice, devfund, treasury] = await hre.ethers.getSigners();

      console.log("alice: ", alice.address);
      console.log("devfund: ", devfund.address);
      console.log("treasury: ", treasury.address);

      want = await getContractAt("ERC20", want_addr);
      oldStrategy = await getContractAt(oldStrategyName, oldStrategyAddress);
      console.log("Fetched old strategy at: ", oldStrategy.address);
      pickleJar = await getContractAt("PickleJar", pickleJarAddress);
      console.log("Fetched pickleJar at: ", pickleJar.address);
      const governanceAddress = await pickleJar.governance();
      console.log("Fetched governance at: ", governanceAddress);
      strategist = await oldStrategy.strategist();
      console.log("Fetched strategist at: ", strategist);
      timelock = await pickleJar.timelock();
      console.log("Fetched timelock at: ", timelock);
      controller = await pickleJar.controller();
      controller = await getContractAt("src/controller-v4.sol:ControllerV4", controller);
      console.log("Fetched controller at: ", controller.address);
      const controllerStrategistAddress = await controller.strategist();
      console.log("Fetched controllerStrategist at: ", controllerStrategistAddress);

      // await unlockAccount(governanceAddress);
      controllerStrategist = await unlockAccount(controllerStrategistAddress);
      console.log("unlocked");

      await alice.sendTransaction({
        to: controllerStrategistAddress,
        value: toWei(1),
      });

      newStrategy = await deployContract(
        newStrategyName,
        alice.address,
        strategist,
        controller.address,
        timelock
      );
      console.log("✅ New Strategy is deployed at ", newStrategy.address);
    });

    it("Should withdraw correctly", async () => {
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();
      console.log("pickleJar earned - 1");

      await controller.connect(controllerStrategist).approveStrategy(want.address, newStrategy.address);
      console.log("approved strategy");
      await controller.connect(controllerStrategist).setStrategy(want.address, newStrategy.address);
      console.log("strategy set");

      await pickleJar.earn();
      console.log("pickleJar earned - 2");

      await increaseTime(60 * 60 * 24 * 15); //travel 15 days

      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await newStrategy.harvest();

      console.log("Ratio after harvest: %s", (await pickleJar.getRatio()).toString());

      let _before = await want.balanceOf(pickleJar.address);
      console.log("\nPicklejar balance before controller withdrawal: ", _before.toString());

      await controller.connect(controllerStrategist).withdrawAll(want.address);

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

    // it("Should harvest correctly", async () => {
    //   const _want = await want.balanceOf(alice.address);
    //   await want.approve(pickleJar.address, _want);
    //   await pickleJar.deposit(_want);
    //   console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
    //   await pickleJar.earn();

    //   await controller.approveStrategy(want.address, newStrategy.address);
    //   await controller.setStrategy(want.address, newStrategy.address);

    //   await pickleJar.earn();

    //   await increaseTime(60 * 60 * 24 * 15); //travel 15 days
    //   const _before = await pickleJar.balance();
    //   let _treasuryBefore = await want.balanceOf(treasury.address);

    //   console.log("Picklejar balance before harvest: ", _before.toString());
    //   console.log("💸 Treasury balance before harvest: ", _treasuryBefore.toString());
    //   console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

    //   await newStrategy.harvest();

    //   const _after = await pickleJar.balance();
    //   let _treasuryAfter = await want.balanceOf(treasury.address);
    //   console.log("Ratio after harvest: ", (await pickleJar.getRatio()).toString());
    //   console.log("\nPicklejar balance after harvest: ", _after.toString());
    //   console.log("💸 Treasury balance after harvest: ", _treasuryAfter.toString());

    //   //20% performance fee is given
    //   const earned = _after.sub(_before).mul(1000).div(800);
    //   const earnedRewards = earned.mul(200).div(1000);
    //   const actualRewardsEarned = _treasuryAfter.sub(_treasuryBefore);
    //   console.log("\nActual reward earned by treasury: ", actualRewardsEarned.toString());

    //   expect(earnedRewards).to.be.eqApprox(actualRewardsEarned, "20% performance fee is not given");

    //   //withdraw
    //   const _devBefore = await want.balanceOf(devfund.address);
    //   _treasuryBefore = await want.balanceOf(treasury.address);
    //   console.log("\n👨‍🌾 Dev balance before picklejar withdrawal: ", _devBefore.toString());
    //   console.log("💸 Treasury balance before picklejar withdrawal: ", _treasuryBefore.toString());

    //   await pickleJar.withdrawAll();

    //   const _devAfter = await want.balanceOf(devfund.address);
    //   _treasuryAfter = await want.balanceOf(treasury.address);
    //   console.log("\n👨‍🌾 Dev balance after picklejar withdrawal: ", _devAfter.toString());
    //   console.log("💸 Treasury balance after picklejar withdrawal: ", _treasuryAfter.toString());

    //   //0% goes to dev
    //   const _devFund = _devAfter.sub(_devBefore);
    //   expect(_devFund).to.be.eq(0, "dev've stolen money!!!!!");

    //   //0% goes to treasury
    //   const _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
    //   expect(_treasuryFund).to.be.eq(0, "treasury've stolen money!!!!");
    // });

    beforeEach(async () => {
      preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};

const doTestMigrationBase = (oldStrategyName, newStrategyName, want_addr) => {
  let alice, want;
  let strategy, newStrategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  describe(`${oldStrategyName} => ${newStrategyName} common migration tests`, () => {
    before("Setup contracts", async () => {
      [alice, devfund, treasury] = await hre.ethers.getSigners();
      governance = alice;
      strategist = alice;
      timelock = alice;

      want = await getContractAt("ERC20", want_addr);

      [controller, strategy, pickleJar] = await setup(
        oldStrategyName,
        want,
        governance,
        strategist,
        timelock,
        devfund,
        treasury
      );

      newStrategy = await deployContract(
        newStrategyName,
        governance.address,
        strategist.address,
        controller.address,
        timelock.address
      );
      console.log("✅ New Strategy is deployed at ", newStrategy.address);
    });

    it("Should withdraw correctly", async () => {
      const _want = await want.balanceOf(alice.address);
      await want.approve(pickleJar.address, _want);
      await pickleJar.deposit(_want);
      console.log("Alice pTokenBalance after deposit: %s\n", (await pickleJar.balanceOf(alice.address)).toString());
      await pickleJar.earn();

      await controller.approveStrategy(want.address, newStrategy.address);
      await controller.setStrategy(want.address, newStrategy.address);

      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 15); //travel 15 days

      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await newStrategy.harvest();

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

      await controller.approveStrategy(want.address, newStrategy.address);
      await controller.setStrategy(want.address, newStrategy.address);

      await pickleJar.earn();

      await increaseTime(60 * 60 * 24 * 15); //travel 15 days
      const _before = await pickleJar.balance();
      let _treasuryBefore = await want.balanceOf(treasury.address);

      console.log("Picklejar balance before harvest: ", _before.toString());
      console.log("💸 Treasury balance before harvest: ", _treasuryBefore.toString());
      console.log("\nRatio before harvest: ", (await pickleJar.getRatio()).toString());

      await newStrategy.harvest();

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

module.exports = {doTestMigrationBase, doTestMigrationBaseWithAddresses};
