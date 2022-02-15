const { verify } = require("crypto");
const { BigNumber } = require("ethers");
const { formatEther, parseEther } = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;

const sleep = async (ms, active=true) => {
  if (active) {
    console.log("Sleeping...")
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
};

const recall = async (fn, ...args) => {
  const delay = async() => new Promise(resolve => setTimeout(resolve, recallTime));
  await delay();
  await fn(...args);
}

const verifyContracts = async (strategies) => {
  console.log(`Verifying contracts...`);
  await Promise.all(strategies.map(async(strategy) => {
    try {
      await hre.run("verify:verify", {
        address: strategy,
        constructorArguments: [governance, strategist, controller, timelock],
      });
    } catch (e) {
      console.error(e);
    }
  }));
}

// Fantom addresses
const governance = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";
const strategist = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const controller = "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6";
const timelock = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";

const testedStrategies = ["0xA6b01164af308d74eD593e24637275ee26Cf9531", "0x20b515d6fA1a248e92350d449286B8D258d91C19", "0xbe9e4d2902f23B83c9d04c1780C09809af5E7b3F", "0x2722930172C38420a4A0Aa7af67C316ebD845Be4", "0x62e02D2E56A18C5DCD5bE447D30D04C9800519E8", "0x767ef1887A71734A1F5198b2bE6dA9c32293ca5e",];

const deployAndTest = async () => {
  //Script Configs
  const sleepToggle = false;
  const sleepTime = 10000;
  const callAttempts = 3;
  const recallTime = 60000

  const contracts = [
    // "src/strategies/fantom/oxd/strategy-oxd-xboo.sol:StrategyOxdXboo",
    // "src/strategies/fantom/spookyswap/strategy-boo-ftm-sushi-lp.sol:StrategyBooFtmSushiLp",
    // "src/strategies/fantom/spookyswap/strategy-boo-btc-eth-lp.sol:StrategyBooBtcEthLp",
    "src/strategies/fantom/spookyswap/strategy-boo-ftm-treeb-lp.sol:StrategyBooFtmTreebLp",
    // "src/strategies/fantom/spookyswap/strategy-boo-ftm-any-lp.sol:StrategyBooFtmAnyLp",
  ];

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
        console.log('Ping!')
        await sleep(sleepTime, sleepToggle);
        recall(checkStrategy, callAttempts)
        try {
          strategy = await StrategyFactory.deploy(governance, strategist, controller, timelock);
          await sleep(sleepTime, sleepToggle);
          await strategy.deployTransaction.wait();
          console.log(`✔️ Strategy deployed at: ${strategy.address}`);
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
      // console.log(`✔️ Strategy deployed at: ${strategy.address}`);

      const executeTx = async (calls, tx, fn, ...args) => {
        await sleep(sleepTime, sleepToggle);
        recall(executeTx, ...args);
        try {
          window[`${tx}`] = await fn(...args);
          if (tx === strategy || tx === jar) {
            await tx.deployTransaction.wait();
          } else {
            await tx.wait();
          }
        } catch (e) {
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left.`);
            await executeTx(...args);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }



      await sleep(sleepTime, sleepToggle);
// Get Want
      const want = await strategy.want();

// Deploy PickleJar contract
      let jar;
      const checkPickleJar = async (calls) => {
        console.log(`Deploying PickleJar...`);
        await sleep(sleepTime, sleepToggle);
        recall(checkPickleJar, callAttempts)
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
        recall(checkApproveTx, callAttempts)
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
        recall(checkApproveStratTx, callAttempts)
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
        recall(checkSetJarTx, callAttempts)
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
        await sleep(sleepTime, sleepToggle);
        recall(checkSetStratTx, callAttempts)
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
        recall(checkDepositTx, callAttempts)
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
        recall(checkEarnTx, callAttempts)
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
      let harvestTx;
      const checkHarvestTx = async(calls) => {
        await sleep(sleepTime, sleepToggle);
        recall(checkHarvestTx, callAttempts)
        try {
          harvestTx = await strategy.harvest();
          await sleep(sleepTime, sleepToggle);
          await harvestTx.wait();
        } catch (e) {
          console.log(`Transaction Failed`);
          console.error(e);
          if (calls > 0) {
            console.log(`Trying again. ${calls} more attempts left`);
            await checkHarvestTx(calls - 1);
          } else {
            console.log('Looks like something is broken!')
          }
        }
      }
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
      ratio: ${ratio.toString()}
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
    `
    ----------------------------
      Here's the full report -
    ----------------------------
    ${allReports.join('\n')}
    `
    )
    for (const strategy of testedStrategies) {
    console.log(`Verifying contract ${strategy.contract} at ${strategy.address}`)
    const verification = await hre.run("verify:verify", {
      address: strategy,
      constructorArguments: [governance, strategist, controller, timelock],
    });
  }
  // verifyContracts(testedStrategies);
};


const main = async () => {
  await deployAndTest();
  // await verifyContracts(testedStrategies);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

