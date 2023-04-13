import "@nomicfoundation/hardhat-toolbox";
import {ethers} from "hardhat";
import {expect, increaseTime, getContractAt, unlockAccount} from "../../utils/testHelper";
import {setup} from "../../utils/setupHelper";
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
      // const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
      // const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
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
        // token0,
        // token1,
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

    it("Should add, update and remove rewards correctly", async () => {
      // TODO
    });
  });
};

// Helpers
const getWantFor = async (signer: SignerWithAddress, strategy: Contract) => {
  const want_amount = ethers.utils.parseEther("1000");
  const whale = await unlockAccount("0xDF9511D05D585Fc5f5Cf572Ebd98e3398314516E");
  const want = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.want());
  await setBalance(whale.address, ethers.utils.parseEther("2"));
  await want.connect(whale).transfer(signer.address, want_amount);
  const _balance = await want.balanceOf(signer.address);
  expect(_balance).to.be.eq(want_amount, "get want failed");
};
