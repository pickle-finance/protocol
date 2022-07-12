const {advanceNDays, advanceSevenDays} = require("./testHelper");
const hre = require("hardhat");
const {ethers} = require("hardhat");
const chalk = require("chalk");

const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const pickleHolder = "0x68759973357F5fB3e844802B3E9bB74317358bf7";
const dillHolderAddr = "0x696A27eA67Cec7D3DA9D3559Cb086db0e814FeD3";
let GaugeV2,
  thisContractAddr,
  pickle,
  pickleHolderSigner,
  dillHolder,
  pickleFromHolder,
  Luffy,
  Zoro,
  Sanji,
  Nami,
  GaugeV2ByLuffy,
  GaugeV2ByZoro,
  GaugeV2BySanji,
  GaugeV2ByNami,
  GaugeV2BydillHolder;

const tenPickles = ethers.utils.parseEther("10");
const notifyRewardAmountMethod = async (print = true, days = 7) => {
  advanceNDays(days);
  // Execute notify reward amount
  // console.log(chalk.blue("PickleHolder's pickle balance ", Number(ethers.utils.formatEther(await pickle.balanceOf(pickleHolder)))));
  let totalSupply = await GaugeV2.totalSupply();
  print ? console.log(chalk.bold("-- -- executing notifyReward -- -- ")) : "";
  print
    ? console.log(chalk.blue("totalSupply pickle in contract =>", Number(ethers.utils.formatEther(totalSupply))))
    : "";
  await pickleFromHolder.approve(thisContractAddr, 0);
  await pickleFromHolder.approve(thisContractAddr, totalSupply);
  await GaugeV2.notifyRewardAmount([totalSupply], {
    gasLimit: 9000000,
  });
  print ? console.log("rewardRates =>", Number(ethers.utils.formatEther(await GaugeV2.rewardRates(0)))) : "";

  // ***************** Luffy claims after every notify reward *****************
  await getAndPrintReward("Luffy", GaugeV2ByLuffy, Luffy.address);
};

const getAndPrintReward = async (actor, gaugeByActor, address) => {
  console.log("Derived supply = ", Number(ethers.utils.formatEther(await gaugeByActor.derivedSupply())));
  console.log(
    `derivedBalances[${actor}] = `,
    Number(ethers.utils.formatEther(await gaugeByActor.derivedBalances(address)))
  );
  await gaugeByActor.getReward();
  console.log(
    chalk.green(
      `${actor}'s pickle balance after getting reward =>`,
      Number(ethers.utils.formatEther(await pickle.balanceOf(address)))
    )
  );
};

describe("Liquidity Staking tests", () => {
  before("Setting up gaugeV2", async () => {
    const signer = ethers.provider.getSigner();
    pickleHolderSigner = ethers.provider.getSigner(pickleHolder);
    dillHolder = ethers.provider.getSigner(dillHolderAddr);
    [Luffy, Zoro, Sanji, Nami] = await ethers.getSigners();

    // console.log("-- Sending gas cost to governance addr --");
    await signer.sendTransaction({
      to: dillHolderAddr,
      value: ethers.BigNumber.from("10000000000000000000"),
      data: undefined,
    });

    console.log("-- Sending gas cost to dillHolder addr --");
    await signer.sendTransaction({
      to: pickleHolder,
      value: ethers.BigNumber.from("1000000000000000000"),
      data: undefined,
    });
    console.log("------------------------ sent ------------------------");
    console.log("pickleholder's ETH balance", await ethers.provider.getBalance(pickleHolder));
    /** unlock accounts */
    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [governanceAddr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [dillHolderAddr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [pickleHolder],
    });

    pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);

    console.log("-- Deploying Gaugev2 contract --");
    const gaugeV2 = await ethers.getContractFactory("/src/dill/gauge-proxy-v2.sol:GaugeV2", pickleHolderSigner);
    const tokenSymbols = ["PICKLE"];
    const rewardTokens = [pickleAddr];
    GaugeV2 = await gaugeV2.deploy(pickleAddr, governanceAddr, pickleHolder, tokenSymbols, rewardTokens);

    await GaugeV2.deployed();

    thisContractAddr = GaugeV2.address;
    console.log("GaugeV2 deployed to:", thisContractAddr);
    //GaugeContract by actors
    GaugeV2ByLuffy = GaugeV2.connect(Luffy);
    GaugeV2ByZoro = GaugeV2.connect(Zoro);
    GaugeV2BySanji = GaugeV2.connect(Sanji);
    GaugeV2ByNami = GaugeV2.connect(Nami);
    GaugeV2BydillHolder = GaugeV2.connect(dillHolder);
    pickleFromHolder = pickle.connect(pickleHolderSigner);
    // console.log("PickleHolder's pickle balance ", Number(ethers.utils.formatEther(await pickle.balanceOf(pickleHolder))));
    console.log("------------------------ Depositing pickle ------------------------");
    await pickleFromHolder.transfer(dillHolderAddr, tenPickles);
    await pickleFromHolder.transfer(Luffy.address, ethers.utils.parseEther("20"));
    await pickleFromHolder.transfer(Zoro.address, tenPickles);
    await pickleFromHolder.transfer(Sanji.address, tenPickles);
    await pickleFromHolder.transfer(Nami.address, tenPickles);
    console.log("------------------------       Done        ------------------------");
    console.log("===================================================================================================");
    console.log(
      "dillHolder's pickle balance ",
      Number(ethers.utils.formatEther(await pickle.balanceOf(dillHolderAddr)))
    );
    console.log("Luffy's pickle balance ", Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address))));
    console.log("Zoro's pickle balance ", Number(ethers.utils.formatEther(await pickle.balanceOf(Zoro.address))));
    console.log("Sanji's pickle balance ", Number(ethers.utils.formatEther(await pickle.balanceOf(Sanji.address))));
    console.log("Nami's pickle balance ", Number(ethers.utils.formatEther(await pickle.balanceOf(Nami.address))));
    console.log("===================================================================================================");
  });

  it("Should test deposit and reward claim by multiple users", async () => {
    // Approvals for deposit
    await pickle.connect(Luffy).approve(thisContractAddr, ethers.utils.parseEther("20"));
    await pickle.connect(Zoro).approve(thisContractAddr, tenPickles);
    await pickle.connect(Sanji).approve(thisContractAddr, tenPickles);
    await pickle.connect(Nami).approve(thisContractAddr, tenPickles);
    await pickle.connect(dillHolder).approve(thisContractAddr, ethers.utils.parseEther("20"));

    // DepositAndLock(start time) for 1 year on the day contract is deployed
    await GaugeV2ByLuffy.depositAndLock(tenPickles, 365 * 86400, false); // will claim just after every notify Reward
    console.log(
      chalk.green(
        "Luffy's pickle balance after deposit and lock(10 pickles) =>",
        Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address)))
      )
    );

    await notifyRewardAmountMethod(); // 7 days
    await notifyRewardAmountMethod(); // 14 days
    await notifyRewardAmountMethod(); // 21 days
    await notifyRewardAmountMethod(); // 28 days
    advanceNDays(2); // 30 days
    // 5 days to go to notify reward

    // Deposit only (start time + 30 days)
    await GaugeV2ByZoro.deposit(tenPickles);
    console.log(
      chalk.green(
        "Zoro's pickle balance after deposit(10 pickles) only",
        Number(ethers.utils.formatEther(await pickle.balanceOf(Zoro.address)))
      )
    );

    await notifyRewardAmountMethod(5); // 35 days

    // DepositAndLock (start time + 35 days) for 180 days
    await GaugeV2ByNami.depositAndLock(tenPickles, 180 * 86400, false);
    console.log(
      chalk.green(
        "Nami's pickle balance after deposit and lock(10 pickles) =>",
        Number(ethers.utils.formatEther(await pickle.balanceOf(Nami.address)))
      )
    );

    // advanceNDays(30);
    await notifyRewardAmountMethod(); // 42 days
    await notifyRewardAmountMethod(); // 49 days
    await notifyRewardAmountMethod(); // 56 days
    await notifyRewardAmountMethod(); // 63 days

    advanceNDays(2); // 65 days
    // 5 days to go to notify reward

    await getAndPrintReward("Nami", GaugeV2ByNami, Nami.address); // get reward by Nami before expiry

    // DepositAndLock with dill balance(start time + 65 days) for 300 days
    await GaugeV2BydillHolder.depositAndLock(tenPickles, 300 * 86400, false);
    console.log(
      chalk.green(
        "DillHolder's pickle balance after deposit and lock(10 pickles) =>",
        Number(ethers.utils.formatEther(await pickle.balanceOf(dillHolderAddr)))
      )
    );

    await notifyRewardAmountMethod(5); // 70 days

    advanceNDays(5); // 75 days
    // 2 days more to notify reward

    //  DepositAndLock again by existing depositor (start time + 75 days) for 180 days // 2nd deposit
    await GaugeV2ByLuffy.depositAndLock(tenPickles, 180 * 86400, false);
    console.log(
      chalk.green(
        "Luffy's pickle balance after deposit and lock(10 pickles) =>",
        Number(ethers.utils.formatEther(await pickle.balanceOf(Luffy.address)))
      )
    );

    //  DepositAndLock  (start time + 75 days) for 30 days
    await GaugeV2BySanji.depositAndLock(tenPickles, 30 * 86400, false);
    console.log(
      chalk.green(
        "Sanji's pickle balance after deposit and lock(10 pickles) =>",
        Number(ethers.utils.formatEther(await pickle.balanceOf(Sanji.address)))
      )
    );

    await notifyRewardAmountMethod(2); // 77 days
    await notifyRewardAmountMethod(); // 84 days

    // Advancing 19 weeks (217 days from start time) so that Nami's stake expires
    for (let i = 0; i < 19; i++) {
      await notifyRewardAmountMethod(false); // 217 days
    }
    await getAndPrintReward("Nami", GaugeV2ByNami, Nami.address); // Nami claims reward after stake expiry

    await getAndPrintReward("Zoro", GaugeV2ByZoro, Zoro.address);

    // Advancing 21 weeks (1 year from start time)
    for (let i = 0; i < 21; i++) {
      await notifyRewardAmountMethod(false); // 364 days
    }
    advanceNDays(2); // 366 days

    // claim reward by Luffy after(1 day) stake lock expired where luffy was claiming his reward regularly
    await getAndPrintReward("Luffy", GaugeV2ByLuffy, Luffy.address);

    // claim reward by dillHolder much after stake lock expired where dillHolder never claimed his reward before
    await getAndPrintReward("dillHolder", GaugeV2BydillHolder, dillHolderAddr);
  });
});
