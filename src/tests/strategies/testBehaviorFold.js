const {expect, increaseTime, getContractAt, increaseBlock, toWei} = require("../utils/testHelper");
const {setup} = require("../utils/setupHelper");
const {ethers, waffle} = require("hardhat");

const doTestBehaviorFold = (strategyName, want_addr, reward_addr, bIncreaseBlock = false, isNative = false) => {
  let alice, want;
  let strategy, pickleJar, controller;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;

  describe(`${strategyName} folding tests`, () => {
    before("Setup contracts", async () => {
      [alice, devfund, treasury] = await hre.ethers.getSigners();
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
        isNative
      );
    });

    it("Should get accrued rewards", async () => {
      let rewardAccrued;
      await deposit(alice);

      rewardAccrued = await strategy.getHarvestable();
      expect(rewardAccrued).to.be.equal(0, "No rewards should have accrued yet");

      await strategy.leverageToMax();

      await increaseTime(60 * 60 * 24 * 1); //travel 1 days
      if (bIncreaseBlock) {
        await increaseBlock(1000);
      }
      rewardAccrued = await strategy.getHarvestable();
      expect(rewardAccrued).to.be.gt("0", "No rewards accrued");
    });

    it("Should sync the colFactor", async () => {
      let colFactor, safeColFactor, shouldSync;
      await deposit(alice);

      // Sets colFactor Buffer to be 2% (safeSync is 3%)
      await strategy.setColFactorLeverageBuffer(20);
      await strategy.leverageToMax();

      // Back to 3%
      await strategy.setColFactorLeverageBuffer(30);
      colFactor = await strategy.callStatic.getColFactor();
      safeColFactor = await strategy.getSafeLeverageColFactor();
      expect(safeColFactor).to.be.lt(colFactor, "Unsafe collateral factor");

      // Sync automatically fixes the colFactor for us
      shouldSync = await strategy.callStatic.sync();
      await strategy.sync();
      expect(shouldSync).to.be.true;

      colFactor = await strategy.callStatic.getColFactor();
      expect(colFactor).to.be.eqApprox(safeColFactor, "colFactor not updated after sync()");

      shouldSync = await strategy.callStatic.sync();
      expect(shouldSync).to.be.false;
    });

    it("Should leverage properly", async () => {
      await deposit(alice);
      const _stratInitialBal = await strategy.balanceOf();

      const _beforeCR = await strategy.callStatic.getColFactor();
      const _beforeLev = await strategy.callStatic.getCurrentLeverage();

      await strategy.leverageToMax();
      const _afterCR = await strategy.callStatic.getColFactor();
      const _afterLev = await strategy.callStatic.getCurrentLeverage();
      const _safeLeverageColFactor = await strategy.getSafeLeverageColFactor();

      expect(_afterCR).to.be.gt(_beforeCR);
      expect(_afterLev).to.be.gt(_beforeLev);
      expect(_safeLeverageColFactor).to.be.eqApprox(_afterCR);

      const _maxLeverage = await strategy.getMaxLeverage();
      expect(_maxLeverage).to.be.gt(toWei(2));

      const leverageTarget = await strategy.getLeveragedSupplyTarget(_stratInitialBal);
      const leverageSupplied = await strategy.callStatic.getSupplied();
      expect(leverageSupplied).to.be.eqApprox(_stratInitialBal.mul(_maxLeverage).div(toWei(1)));

      expect(leverageSupplied).to.be.eqApprox(leverageTarget);

      const unleveragedSupplied = await strategy.callStatic.getSuppliedUnleveraged();

      expect(unleveragedSupplied).to.be.eqApprox(_stratInitialBal);
    });

    it("Should deleverage properly", async () => {
      await deposit(alice);
      await strategy.leverageToMax();

      const _beforeCR = await strategy.callStatic.getColFactor();
      const _beforeLev = await strategy.callStatic.getCurrentLeverage();
      await strategy.deleverageToMin();
      const _afterCR = await strategy.callStatic.getColFactor();
      const _afterLev = await strategy.callStatic.getCurrentLeverage();

      expect(_afterCR).to.be.lt(_beforeCR);
      expect(_afterLev).to.be.lt(_beforeLev);
      expect(_afterCR).to.be.eq("0"); // 0 since we're not borrowing anything

      const unleveragedSupplied = await strategy.callStatic.getSuppliedUnleveraged();
      const supplied = await strategy.callStatic.getSupplied();
      expect(unleveragedSupplied).to.be.eqApprox(supplied);
    });

    it("Should withdrawSome() properly", async () => {
      await deposit(alice);
      await strategy.leverageToMax();

      const _before = await getWantBalance(alice.address);
      await pickleJar.withdraw(toWei(25));
      const _after = await getWantBalance(alice.address);

      expect(_after).to.be.gt(_before);
      expect(_after).to.be.eqApprox(_before.add(toWei(25)));

      const _before2 = await getWantBalance(alice.address);
      await pickleJar.withdraw(toWei(30));
      const _after2 = await getWantBalance(alice.address);

      expect(_after2).to.be.gt(_before2);
      expect(_after2).to.be.eqApprox(_before2.add(toWei(30)));

      // Make sure we're still leveraging
      const _leverage = await strategy.callStatic.getCurrentLeverage();

      expect(_leverage).to.be.gt(toWei(1));
    });

    it("Should withdrawAll() properly", async () => {
      const _want = await getWantBalance(alice.address);
      await deposit(alice);
      await strategy.leverageToMax();

      await increaseTime(60 * 60 * 24 * 1); //travel 1 days
      if (bIncreaseBlock) {
        await increaseBlock(1000);
      }

      await strategy.harvest();
      // Testing controller withdrawal
      const _before = await want.balanceOf(pickleJar.address);
      await controller.withdrawAll(want.address);
      const _after = await want.balanceOf(pickleJar.address);

      expect(_after).to.be.gt(_before);

      // Testing user withdrawal
      await pickleJar.withdrawAll();

      const _after2 = await getWantBalance(alice.address);

      // Gained some interest
      expect(_after2).to.be.gt(_want);
    });

    it("Should send rewards to treasury on harvest", async () => {
      await deposit(alice);

      await increaseTime(60 * 60 * 24 * 1); //travel 1 days
      if (bIncreaseBlock) {
        await increaseBlock(1000);
      }

      // Testing controller withdrawal
      const reward = await getContractAt("src/lib/erc20.sol:ERC20", reward_addr);
      const _treasuryBefore = await reward.balanceOf(treasury.address);

      await strategy.harvest();

      const _treasuryAfter = await reward.balanceOf(treasury.address);

      expect(_treasuryAfter).to.be.gt(_treasuryBefore);
    });

    it("Should execute end-to-end functions", async () => {
      await deposit(alice);

      const initialSupplied = await strategy.callStatic.getSupplied();
      const initialBorrowed = await strategy.callStatic.getBorrowed();
      const initialBorrowable = await strategy.callStatic.getBorrowable();
      const marketColFactor = await strategy.getMarketColFactor();
      const maxLeverage = await strategy.getMaxLeverage();

      // Earn deposits 95% into strategy
      expect(initialSupplied).to.be.eqApprox(toWei(950));

      expect(initialBorrowable).to.be.eqApprox(initialSupplied.mul(marketColFactor).div(toWei(1)));
      expect(initialBorrowed).to.be.eq("0");

      // Leverage to Max
      await strategy.leverageToMax();

      const supplied = await strategy.callStatic.getSupplied();
      const borrowed = await strategy.callStatic.getBorrowed();
      const borrowable = await strategy.callStatic.getBorrowable();
      const currentColFactor = await strategy.callStatic.getColFactor();
      const safeLeverageColFactor = await strategy.getSafeLeverageColFactor();

      expect(supplied).to.be.eqApprox(initialSupplied.mul(maxLeverage).div(toWei(1)));
      expect(borrowed).to.be.eqApprox(supplied.mul(safeLeverageColFactor).div(toWei(1)));

      expect(borrowable).to.be.eqApprox(supplied.mul(marketColFactor.sub(currentColFactor)).div(toWei(1)));
      expect(currentColFactor).to.be.eqApprox(safeLeverageColFactor);
      expect(marketColFactor).to.be.gt(currentColFactor);
      expect(marketColFactor).to.be.gt(safeLeverageColFactor);

      // Deleverage
      await strategy.deleverageToMin();

      const deleverageSupplied = await strategy.callStatic.getSupplied();
      const deleverageBorrowed = await strategy.callStatic.getBorrowed();
      const deleverageBorrowable = await strategy.callStatic.getBorrowable();

      expect(deleverageSupplied).to.be.eqApprox(initialSupplied);
      expect(deleverageBorrowed).to.be.eq("0");
      expect(deleverageBorrowable).to.be.eqApprox(initialBorrowable);
    });

    it("Should deleverage incrementally", async () => {
      let supplied;
      await deposit(alice);
      await strategy.leverageToMax();

      await strategy.deleverageUntil(toWei(2000));
      supplied = await strategy.callStatic.getSupplied();
      expect(supplied).to.be.eqApprox(toWei(2000));

      await strategy.deleverageUntil(toWei(1800));
      supplied = await strategy.callStatic.getSupplied();
      expect(supplied).to.be.eqApprox(toWei(1800));

      await strategy.deleverageUntil(toWei(1200));
      supplied = await strategy.callStatic.getSupplied();
      expect(supplied).to.be.eqApprox(toWei(1200));
    });

    it("Should accomodate multiple users' withdrawals", async () => {
      // Give half from Alice to devfund for this test
      await want.connect(alice).transfer(devfund.address, (await getWantBalance(alice.address)).div(2));
      const aliceOriginal = await getWantBalance(alice.address);
      const devOriginal = await getWantBalance(devfund.address);
      await deposit(alice);
      await strategy.leverageToMax();

      // User 2 has entered the chat
      await deposit(devfund);
      const quarterBalance = (await pickleJar.balanceOf(alice.address)).div(4);

      // Alice withdraws quarter
      const aliceBefore1 = await getWantBalance(alice.address);
      await pickleJar.connect(alice).withdraw(quarterBalance);
      const aliceAfter1 = await getWantBalance(alice.address);
      expect(aliceAfter1).to.be.eqApprox(aliceBefore1.add(quarterBalance));

      await increaseTime(60 * 60 * 24 * 1); //travel 1 days
      if (bIncreaseBlock) {
        await increaseBlock(1000);
      }

      await strategy.harvest();

      // Alice withdraws another quarter
      const aliceBefore2 = await getWantBalance(alice.address);
      await pickleJar.connect(alice).withdraw(quarterBalance);
      const aliceAfter2 = await getWantBalance(alice.address);

      expect(aliceAfter2).to.be.eqApprox(aliceBefore2.add(quarterBalance));
      expect(aliceAfter2).to.be.eqApprox(aliceBefore1.add(quarterBalance.mul(2)));

      // Devfund withdraws all
      await pickleJar.connect(devfund).withdrawAll();

      const devAfter = await getWantBalance(devfund.address);

      // Alice withdraws her remaining
      await pickleJar.connect(alice).withdrawAll();
      const aliceFinal = await getWantBalance(alice.address);
      expect(devAfter).to.be.eqApprox(devOriginal);
      expect(aliceFinal).to.be.eqApprox(aliceOriginal);
    });

    const deposit = async (wallet) => {
      if (!isNative) {
        const _want = await getWantBalance(wallet.address);
        await want.connect(wallet).approve(pickleJar.address, _want);

        await pickleJar.connect(wallet).deposit(_want);
      } else {
        const value = toWei(1000);
        await pickleJar.connect(wallet).deposit({
          value,
        });
      }
      await pickleJar.earn();
    };

    const getWantBalance = async (address) => {
      if (isNative) return await waffle.provider.getBalance(address);
      return await want.balanceOf(address);
    };

    beforeEach(async () => {
      preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
      await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
  });
};

module.exports = {doTestBehaviorFold};
