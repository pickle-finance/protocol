const {advanceSevenDays} = require("./testHelper");
const hre = require("hardhat");
const {ethers} = require("hardhat");
const {expect} = require("chai");

const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const userAddr = "0x5c4D8CEE7dE74E31cE69E76276d862180545c307";
const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const pickleHolder = "0x68759973357F5fB3e844802B3E9bB74317358bf7";
const dillHolder = "0x696A27eA67Cec7D3DA9D3559Cb086db0e814FeD3";
const zeroAddr = "0x0000000000000000000000000000000000000000";

let userSigner,
  Jar,
  VirtualGaugeV2,
  thisContractAddr,
  pickle,
  pickleHolderSigner,
  governanceSigner,
  dillHolderSigner,
  Luffy,
  Zoro,
  Sanji,
  Nami;

const fivePickle = ethers.utils.parseEther("5");

const printStakes = async (address) => {
  let stakes = await Jar.getLockedStakesOf(address);
  console.log("********************* Locked stakes ********************************************");
  stakes.forEach((stake, index) => {
    console.log(
      "Liquidity in stake with index",
      index,
      ethers.utils.formatEther(stake.liquidity),
      "ending timestamp",
      stake.ending_timestamp,
      "are",
      stake.isPermanentlyLocked ? "locked" : "unlocked"
    );
  });
  console.log("*******************************************************************************");
};

describe("Liquidity Staking tests", () => {
  before("Setting up gaugeV2", async () => {
    const signer = ethers.provider.getSigner();
    pickleHolderSigner = ethers.provider.getSigner(pickleHolder);
    userSigner = ethers.provider.getSigner(userAddr);
    governanceSigner = ethers.provider.getSigner(governanceAddr);
    [Luffy, Zoro, Sanji, Nami] = await ethers.getSigners();

    console.log("-- Sending gas cost to governance addr --");
    await signer.sendTransaction({
      to: governanceAddr,
      value: ethers.BigNumber.from("10000000000000000000"),
      data: undefined,
    });

    console.log("-- Sending gas cost to dillHolder addr --");
    await signer.sendTransaction({
      to: dillHolder,
      value: ethers.BigNumber.from("10000000000000000000"),
      data: undefined,
    });

    console.log("------------------------ sent ------------------------");

    /** unlock accounts */
    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [governanceAddr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [userAddr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [dillHolder],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [pickleHolder],
    });

    pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);

    console.log("-- Deploying jar contract --");
    const jar = await ethers.getContractFactory("/src/dill/JarTemp.sol:JarTemp", pickleHolderSigner);
    Jar = await jar.deploy();
    await Jar.deployed();
    console.log("Jar deployed at", Jar.address);

    console.log("-- Deploying VirtualGaugeV2 contract --");
    const virtualGaugeV2 = await ethers.getContractFactory(
      "/src/dill/gauge-proxy-v2.sol:VirtualGaugeV2",
      pickleHolderSigner
    );
    await expect(
      virtualGaugeV2.deploy(zeroAddr, governanceAddr, pickleHolder, ["PICKLE"], [pickleAddr])
    ).to.be.revertedWith("cannot set zero address");
    VirtualGaugeV2 = await virtualGaugeV2.deploy(Jar.address, governanceAddr, pickleHolder, ["PICKLE"], [pickleAddr]);
    await VirtualGaugeV2.deployed();
    thisContractAddr = VirtualGaugeV2.address;
    console.log("VirtualGaugeV2 deployed to:", thisContractAddr);

    const pickleFromHolder = pickle.connect(pickleHolderSigner);

    dillHolderSigner = ethers.provider.getSigner(dillHolder);

    console.log("------------------------ Depositing pickle ------------------------");
    await pickleFromHolder.transfer(dillHolder, ethers.utils.parseEther("100"));
    await pickleFromHolder.transfer(userAddr, ethers.utils.parseEther("10"));
    await pickleFromHolder.transfer(Luffy.address, ethers.utils.parseEther("10"));
    await pickleFromHolder.transfer(Zoro.address, ethers.utils.parseEther("10"));
    await pickleFromHolder.transfer(Sanji.address, ethers.utils.parseEther("10"));
    await pickleFromHolder.transfer(Nami.address, ethers.utils.parseEther("10"));
    console.log("------------------------       Done        ------------------------");
  });
  it("Should test staking successFully", async () => {
    // approve => jar by => Luffy
    console.log("Luffy's pickle balance => ", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    // await pickle.connect(Luffy).approve(Jar.address, fivePickle);

    console.log(
      "Pickle Balance of Luffy before depositing =>",
      Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address)))
    );

    //Approve pickle for deposit
    await pickle.connect(Luffy).approve(Jar.address, fivePickle);

    await expect(Jar.depositForByJar(fivePickle, Luffy.address)).to.be.revertedWith("set jar first");

    // Set Jar
    await Jar.setVirtualGauge(VirtualGaugeV2.address);
    const jarAd = await Jar.getVirtualGauge();
    console.log("Virtual Gauge =>", jarAd);

    // Deposit pickle
    console.log("-- Depositing 5 pickle for Luffy --");
    await Jar.depositForByJar(fivePickle, Luffy.address);
    console.log("Jar Balance of Luffy", Number(ethers.utils.formatEther(await Jar.getBalanceOf(Luffy.address))));
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    console.log("Pickle Balance of Jar =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Jar.address))));

    //Approve pickle for deposit and lock
    await pickle.connect(Luffy).approve(Jar.address, fivePickle);

    // Deposit and lock
    console.log("-- Deposit and lock 5 pickle for Luffy --");

    await expect(
      Jar.depositForAndLockByJar(0, Luffy.address, 86400 * 30, false, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Cannot stake 0");

    await Jar.depositForAndLockByJar(fivePickle, Luffy.address, 86400 * 30, false, {
      gasLimit: 9000000,
    });
    //Approve pickle for deposit and lock
    await pickle.connect(Sanji).approve(Jar.address, fivePickle);

    // Deposit and lock
    console.log("-- Deposit and lock 5 pickle for Sanji --");
    await Jar.depositForAndLockByJar(fivePickle, Sanji.address, 86400 * 300, false, {
      gasLimit: 9000000,
    });

    //Approve pickle for deposit and lock
    await pickle.connect(Zoro).approve(Jar.address, fivePickle);

    // Deposit and lock
    console.log("-- Deposit and lock 5 pickle for Sanji --");
    await Jar.depositForAndLockByJar(fivePickle, Zoro.address, 86400 * 300, false, {
      gasLimit: 9000000,
    });
    console.log("Jar Balance of Luffy", Number(ethers.utils.formatEther(await Jar.getBalanceOf(Luffy.address))));
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    console.log("Pickle Balance of Jar =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Jar.address))));

    await printStakes(Luffy.address);

    advanceSevenDays();

    // withdraw
    console.log("-- Withdrawing Luffy's stake");

    await expect(Jar.withdrawByJar(Luffy.address, 10)).to.be.revertedWith("Stake not found");

    await Jar.withdrawByJar(Luffy.address, 0);
    console.log("Jar Balance of Luffy", Number(ethers.utils.formatEther(await Jar.getBalanceOf(Luffy.address))));
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    console.log("Pickle Balance of Jar =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Jar.address))));
    await printStakes(Luffy.address);

    // notify reward
    const bal = await pickle.balanceOf(Jar.address);
    await pickle.connect(pickleHolderSigner).approve(VirtualGaugeV2.address, bal);
    // await VirtualGaugeV2.notifyRewardAmount([bal]);
    await expect(
      VirtualGaugeV2.connect(Luffy).notifyRewardAmount([bal], {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Caller is not RewardsDistribution contract");

    console.log("-- Executing NotifyReward --");
    await VirtualGaugeV2.connect(pickleHolderSigner).notifyRewardAmount([bal], {
      gasLimit: 9000000,
    });
    //get Reward
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    console.log("Total Supply =>", await VirtualGaugeV2.totalSupply());
    console.log("--Executing get reward --");
    await Jar.getRewardByJar(Luffy.address, {
      gasLimit: 90000000,
    });
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));

    console.log("-- Unlocking Stakes for Luffy --");
    // console.log()
    await VirtualGaugeV2.connect(governanceSigner).unlockStakeForAccount(Luffy.address);

    await printStakes(Luffy.address);
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    console.log("-- Withdrawing --");
    await Jar.withdrawAllByJar(Luffy.address);
    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    // print Luffy's Stakes
    await printStakes(Luffy.address);

    console.log("Pickle Balance of Luffy =>", Number(ethers.utils.formatEther(await pickle.balanceOf(Sanji.address))));

    // Test multipliers for 1 year and 300 year should be equal
    const multiplierForOneYear = await VirtualGaugeV2.lockMultiplier(86400 * 365);
    const multiplierForTwentyYear = await VirtualGaugeV2.lockMultiplier(86400 * 365 * 20);
    expect(multiplierForOneYear).to.eq(multiplierForTwentyYear);

    console.log(" -- Emergency unlock all stakes -- ");
    await VirtualGaugeV2.connect(governanceSigner).unlockStakes();

    console.log(" -- Zoro's stake -- ");
    await printStakes(Zoro.address);

    console.log("-- Exiting Zoro -- ");
    await Jar.exitByJar(Zoro.address);

    console.log(" -- Zoro's stake after exit -- ");
    await printStakes(Zoro.address);

    await expect(
      VirtualGaugeV2.connect(governanceSigner).setMaxRewardsDuration(86400 * 400, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Reward period incomplete");
    await advanceSevenDays();
    await advanceSevenDays();

    // test various setters
    console.log(" -- Testing MaxDuration setters -- ");
    await expect(VirtualGaugeV2.setMaxRewardsDuration(86400, {gasLimit: 9000000})).to.be.revertedWith(
      "Operation allowed by only governance"
    );
    await expect(
      VirtualGaugeV2.connect(governanceSigner).setMaxRewardsDuration(8640, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Rewards duration too short");
    const newMaxTime = 86400 * 400;
    await VirtualGaugeV2.connect(governanceSigner).setMaxRewardsDuration(newMaxTime, {
      gasLimit: 9000000,
    });
    const maxTime = await VirtualGaugeV2.lockTimeForMaxMultiplier();
    expect(newMaxTime).to.be.eq(maxTime);

    console.log(" -- Testing multiplier setters -- ");
    await expect(VirtualGaugeV2.setMultipliers(1, {gasLimit: 9000000})).to.be.revertedWith(
      "Operation allowed by only governance"
    );
    await expect(
      VirtualGaugeV2.connect(governanceSigner).setMultipliers(10 ** 14, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Multiplier must be greater than or equal to 1e18");
    console.log("Multiplier =>", await VirtualGaugeV2.lockMaxMultiplier());
    const newMultilier = ethers.utils.parseEther("1"); //new BigNumber(10 ** 19).toFixed();
    await VirtualGaugeV2.connect(governanceSigner).setMultipliers(newMultilier, {
      gasLimit: 9000000,
    });
    const maxMultiplier = await VirtualGaugeV2.lockMaxMultiplier();
    expect(maxMultiplier).to.be.eq(newMultilier);

    await expect(VirtualGaugeV2.setJar(Jar.address)).to.be.revertedWith("Operation allowed by only governance");
    await expect(VirtualGaugeV2.connect(governanceSigner).setJar(zeroAddr)).to.be.revertedWith("cannot set to zero");

    await expect(VirtualGaugeV2.connect(governanceSigner).setJar(Jar.address)).to.be.revertedWith("Jar is already set");

    //maxMultiplier and duration
    const multiplierFor1year = await VirtualGaugeV2.lockMultiplier(86400 * 365);
    const multiplierFor2year = await VirtualGaugeV2.lockMultiplier(86400 * 365 * 2);
    expect(multiplierFor1year).to.equal(multiplierFor2year);

    const rewardForDuration = await VirtualGaugeV2.getRewardForDuration();
    console.log("rewardForDuration =>", rewardForDuration);
  });
  it("Test partial withdrawal", async () => {
    await pickle.connect(dillHolderSigner).approve(Jar.address, 0);

    const DillHolderPickleBalance = await pickle.connect(dillHolderSigner).balanceOf(dillHolder);
    await pickle.connect(dillHolderSigner).approve(Jar.address, DillHolderPickleBalance);
    await expect(
      Jar.depositForAndLockByJar(fivePickle, dillHolder, 86, false, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Minimum stake time not met");

    await expect(
      Jar.depositForAndLockByJar(fivePickle, dillHolder, 86400 * 401, false, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Trying to lock for too long");

    await expect(
      Jar.depositForAndLockByJar(fivePickle, dillHolder, 86, false, {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Minimum stake time not met");

    console.log(" -- deposit and lock 5 pickle for 3 days -- ");
    await Jar.depositForAndLockByJar(fivePickle, dillHolder, 86400 * 3, false, {
      gasLimit: 9000000,
    });
    console.log(" -- deposit and lock 5 pickle for 365 days -- ");
    await Jar.depositForAndLockByJar(fivePickle, dillHolder, 86400 * 365, false, {
      gasLimit: 9000000,
    });

    console.log(" -- deposit and lock 5 pickle 1 day -- ");
    await Jar.depositForAndLockByJar(fivePickle, dillHolder, 86400, false, {
      gasLimit: 9000000,
    });

    console.log(" -- deposit and lock 5 pickle permanently -- ");
    await Jar.depositForAndLockByJar(fivePickle, dillHolder, 86400, true, {
      gasLimit: 9000000,
    });
    // console.log(" -- deposit all remaining pickle -- ");
    // await Jar.depositAll({ gasLimit: 9000000 });

    await printStakes(dillHolder);
    advanceSevenDays();

    await expect(Jar.partialWithdrawalByJar(dillHolder, ethers.utils.parseEther("5000"))).to.be.revertedWith(
      "Withdraw amount exceeds balance"
    );

    // Withdraw 5 pickle (= liquidity in first unlocked stake)
    console.log(" -- Partially withdrawing 5 pickle -- ");
    await Jar.partialWithdrawalByJar(dillHolder, fivePickle); // working fine

    await printStakes(dillHolder);

    // Withdraw 2 pickle (< liquidity in first unlocked stake)
    console.log(" -- Partially withdrawing 2 pickle -- ");
    await Jar.partialWithdrawalByJar(dillHolder, ethers.utils.parseEther("2")); // working fine

    await printStakes(dillHolder);

    // Withdraw 5 pickle (> liquidity in first unlocked stake)
    console.log(" -- Partially withdrawing 5 pickle -- ");
    await Jar.partialWithdrawalByJar(dillHolder, fivePickle);

    await printStakes(dillHolder);

    // await expect(
    //   Jar.withdrawByJar(dillHolder, 3)
    // ).to.be.revertedWith("Stake is still locked!");

    //set jar to other address
    await VirtualGaugeV2.connect(governanceSigner).setAuthoriseAddress(governanceAddr, true);
    await expect(VirtualGaugeV2.connect(governanceSigner).setAuthoriseAddress(governanceAddr, true)).to.be.revertedWith(
      "address is already set to given value"
    );

    console.log("-- Exiting dillHolder");
    await Jar.exitByJar(dillHolder);

    await printStakes(dillHolder);
  });
});
