const { verify } = require("crypto");
const { BigNumber } = require("ethers");
const { formatEther, parseEther } = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;

const sleep = async (ms, active) => {
  if (active) {
    console.log("Sleeping...")
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
};
// This function is meant to run multiple verifications
// Simultaneously with Promise.all
const verifyContracts = async (strategies) => {
  console.log(`Verifying contracts...`);
  await Promise.all(strategies.map(async(strategy) => {
    console.log(`Verifying contract ${strategy.contract} at ${strategy.address}`)
    await hre.run("verify:verify", {
      address: strategy.address,
      constructorArguments: [governance, strategist, controller, timelock],
    });
  }));
}

// Fantom addresses
const governance = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";
const strategist = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const controller = "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6";
const timelock = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";

const deployAndTest = async () => {
  //Script Configs
  const sleepToggle = false;
  const sleepTime = 10000;
  let callAttempts = 3;
  const callCleanup = () => callAttempts = 3;

  const contracts = [
    // "src/strategies/fantom/oxd/strategy-oxd-xboo.sol:StrategyOxdXboo",
    "src/strategies/fantom/spookyswap/strategy-boo-ftm-sushi-lp.sol:StrategyBooFtmSushiLp",
    // "src/strategies/fantom/spookyswap/strategy-boo-btc-eth-lp.sol:StrategyBooBtcEthLp",
    "src/strategies/fantom/spookyswap/strategy-boo-ftm-treeb-lp.sol:StrategyBooFtmTreebLp",
    "src/strategies/fantom/spookyswap/strategy-boo-ftm-any-lp.sol:StrategyBooFtmAnyLp",
  ];

  const testedStrategies = [];
  const allReports = [];

  for (const contract of contracts) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    // console.log("" + StrategyFactory.deploy);
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);
    const currentContract = contract.substring(contract.lastIndexOf(":") + 1);

    try {
// Deploy Strategy contract
      console.log(`Deploying ${currentContract}...`);
      let strategy;
      const checkStrategy = async (calls) => {
        await sleep(sleepTime, sleepToggle);
        try {
          strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);
          await sleep(sleepTime, sleepToggle);
          await strategy.deployTransaction.wait();
        } catch (e) {
            console.log(`Transaction Failed`);
            console.error(e);
            if (calls > 0) {
              console.log(`Trying again. ${calls} more attempts left.`)
              await checkStrategy(calls - 1);
            } else {
              console.log('Looks like something is broken!')
            }
          }
        }
      await checkStrategy(callAttempts);
      console.log(`✔️ Strategy deployed at: ${strategy.address}`);

      await sleep(sleepTime, sleepToggle);
// Get Want
      const want = await strategy.want();

// Deploy PickleJar contract
      let jar;
      const checkPickleJar = async (calls) => {
        console.log(`Deploying PickleJar...`);
        await sleep(sleepTime, sleepToggle);
        try {
          jar = await PickleJarFactory.deploy(want, governance, timelock, controller);
          await sleep(sleepTime, sleepToggle);
          await jar.deployTransaction.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`)
            await checkPickleJar(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkPickleJar(callAttempts);
      await sleep(sleepTime, sleepToggle);
      console.log(`✔️ PickleJar deployed at: ${jar.address}`);

// Log Want
      console.log(`Want address is: ${want}`);
      console.log(`Approving want token for deposit...`);
      const wantContract = await ethers.getContractAt("ERC20", want);
      await sleep(sleepTime, sleepToggle);

// Approve Want
      let approveTx;
      const checkApproveTx = async(calls) => {
        await sleep(sleepTime, sleepToggle);
        try {
          approveTx = await wantContract.approve(jar.address, ethers.constants.MaxUint256);
          await sleep(sleepTime, sleepToggle);
          await approveTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            checkApproveTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkApproveTx(callAttempts);
      await sleep(sleepTime, sleepToggle);
      console.log(`✔️ Successfully approved Jar to spend want`);

      console.log(`Setting all the necessary stuff in controller...`);

// Approve Strategy
      let approveStratTx;
      const checkApproveStratTx = async(calls) => {
        await sleep(sleepTime, sleepToggle);
        try {
          approveStratTx = await Controller.approveStrategy(want, strategy.address);
          await sleep(sleepTime, sleepToggle);
          await approveStratTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            await checkApproveStratTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkApproveStratTx(callAttempts);
      console.log(`Strategy Approved!`)
      await sleep(sleepTime, sleepToggle);


// Set Jar
      let setJarTx;
      const checkSetJarTx = async(calls) => {
        await sleep(sleepTime, sleepToggle);
        try {
          setJarTx = await Controller.setJar(want, jar.address);
          await sleep(sleepTime, sleepToggle);
          await setJarTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            await checkSetJarTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkSetJarTx(callAttempts);
      console.log(`Jar Set!`)
      await sleep(sleepTime, sleepToggle);

// Set Strategy
      let setStratTx;
      const checkSetStratTx = async(calls) => {
        try {
          setStratTx = await Controller.setStrategy(want, strategy.address);
          await sleep(sleepTime, sleepToggle);
          await setStratTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            await checkSetStratTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkSetJarTx(callAttempts);
      console.log(`Strategy Set!`)
      await sleep(sleepTime, sleepToggle);

      console.log(`✔️ Controller params all set!`);
      console.log(`Depositing in Jar...`);

// Deposit Want
      let depositTx;
      const checkDepositTx = async(calls) => {
        await sleep(sleepTime, sleepToggle);
        try {
          depositTx = await jar.depositAll();
          await sleep(sleepTime, sleepToggle);
          await depositTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            await checkDepositTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkDepositTx(callAttempts);
      console.log(`✔️ Successfully deposited want in Jar`);
      await sleep(sleepTime, sleepToggle);

// Call Earn
      console.log(`Calling earn...`);
      let earnTx;
      const checkEarnTx = async(calls) => {
        await sleep(sleepTime, sleepToggle);
        try {
          earnTx = await jar.earn();
          await sleep(sleepTime, sleepToggle);
          await earnTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            await checkEarnTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
      await checkEarnTx(callAttempts);
      console.log(`✔️ Successfully called earn`);
      await sleep(sleepTime, sleepToggle);

      console.log(`Waiting for 30 seconds before harvesting...`);
      await sleep(30000);

      const harvestTx = await strategy.harvest();
      await sleep(sleepTime, sleepToggle);

      await harvestTx.wait();
      await sleep(sleepTime, sleepToggle);

      const ratio = await jar.getRatio();

      if (ratio.gt(BigNumber.from(parseEther("1")))) {
        console.log(`✔️ Harvest was successful, ending ratio of ${ratio.toString()}`);
        console.log(`Adding ${currentContract} deployed at ${strategy.address} to testedStrategies`)
        testedStrategies.push({contract: currentContract, address: strategy.address})
      } else {
        console.log(`❌ Harvest failed, ending ratio of ${ratio.toString()}`);
      }

      const report =
      `
      Jar Info -
      name: ${currentContract}
      want: ${want}
      picklejar: ${jar.address}
      strategy: ${strategy.address}
      `;

      console.log(report)
      allReports.push(report)
    } catch (e) {
      console.log(`Oops something went wrong...`);
      console.error(e);
      await sleep(5000);
    }
  }
  console.log(
    `Here's the full report -
    ${allReports.join('\n')}
    `
    )
    for (const strategy of testedStrategies) {
    console.log(`Verifying contract ${strategy.contract} at ${strategy.address}`)
    const verification = await hre.run("verify:verify", {
      address: strategy.address,
      constructorArguments: [governance, strategist, controller, timelock],
    });
  }
  // verifyContracts(testedStrategies);
};


const main = async () => {
  await deployAndTest();
  // await verifyContracts();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

