const { verify } = require("crypto");
const { BigNumber } = require("ethers");
const { formatEther, parseEther } = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;
const { exec } = require("child_process");

// Script configs
const sleepToggle = true;
const sleepTime = 15000;
const recallTime = 60000
const callAttempts = 3;

// References
const txRefs = {};
const allReports = [];

// Addresses & Contracts
const governance = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";
const strategist = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const controller = "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6";
const timelock = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";

const contracts = [
  // "src/strategies/fantom/oxd/strategy-oxd-xboo.sol:StrategyOxdXboo",
  // "src/strategies/fantom/spookyswap/strategy-boo-ftm-sushi-lp.sol:StrategyBooFtmSushiLp",
  // "src/strategies/fantom/spookyswap/strategy-boo-btc-eth-lp.sol:StrategyBooBtcEthLp",
  "src/strategies/fantom/spookyswap/strategy-boo-ftm-beets-lp.sol:StrategyBooFtmBeetsLp",
  // "src/strategies/fantom/spookyswap/strategy-boo-ftm-any-lp.sol:StrategyBooFtmAnyLp",
];

const testedStrategies = [
  "0xaD5b7F1Af5f58b17185C24D2E6C011D49EAA5F4c",
  "0x767ef1887A71734A1F5198b2bE6dA9c32293ca5e",
  "0x08751fAC1dA7D063daF6a2a6B5D6770F2f5517f7",
];

// Functions
const sleep = async (ms, active = true) => {
  if (active) {
    console.log("Sleeping...")
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
};

const recall = async (fn, ...args) => {
  const delay = async () => new Promise(resolve => setTimeout(resolve, recallTime));
  await delay();
  await fn(...args);
}

const verifyContracts = async (strategies) => {
  await exec("npx hardhat clean");
  console.log(`Verifying contracts...`);
  await Promise.all(strategies.map(async (strategy) => {
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

const executeTx = async (calls, tx, fn, ...args) => {
  await sleep(sleepTime, sleepToggle);
  if (!txRefs[tx]) { recall(executeTx, calls, tx, fn, ...args) }
  try {
    if (!txRefs[tx]) {
      console.log(fn.toString())
      ///// WIP ////////////////
      txRefs[tx] = await fn(...args)
      ///// WIP ////////////////
      if (tx === 'strategy' || tx === 'jar') {
        await tx.deployTransaction.wait();
      } else {
        await tx.wait();
      }
    }
    console.log(`Transaction receipt: ${txRefs[tx]}`)
  } catch (e) {
    console.error(e);
    if (calls > 0) {
      console.log(`Trying again. ${calls} more attempts left.`);
      await executeTx(calls - 1, tx, fn, ...args);
    } else {
      console.log('Looks like something is broken!');
      return;
    }
  }
  await sleep(sleepTime, sleepToggle);
}
const deployAndTest = async () => {
  for (const contract of contracts) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    console.log(StrategyFactory)
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);
    txRefs['name'] = contract.substring(contract.lastIndexOf(":") + 1);

    try {
      // Deploy Strategy contract
      console.log(`Deploying ${txRefs['name']}...`);
      await executeTx(callAttempts, 'strategy', StrategyFactory.deploy, governance, strategist, controller, timelock);
      console.log(`✔️ Strategy deployed at: ${txRefs['strategy'].address}`);

      // Get Want
      txRefs['want'] = await txRefs['strategy'].want();

      // Deploy PickleJar contract
      await executeTx(callAttempts, 'jar', PickleJarFactory.deploy, txRefs['want'], governance, timelock, controller);
      console.log(`✔️ PickleJar deployed at: ${txRefs['jar'].address}`);

      // Log Want
      console.log(`Want address is: ${txRefs['want']}`);
      console.log(`Approving want token for deposit...`);
      txRefs['wantContract'] = await ethers.getContractAt("ERC20", txRefs['want']);

      // Approve Want
      await executeTx(callAttempts, 'approveTx', txRefs['wantContract'].approve, txRefs['jar'].address, ethers.constants.MaxUint256);
      console.log(`✔️ Successfully approved Jar to spend want`);
      console.log(`Setting all the necessary stuff in controller...`);

      // Approve Strategy
      await executeTx(callAttempts, 'approveStratTx', Controller.approveStrategy, txRefs['want'], txRefs['strategy'].address);
      console.log(`Strategy Approved!`)

      // Set Jar
      await executeTx(callAttempts, 'setJarTx', Controller.setJar, txRefs['want'], txRefs['jar'].address);
      console.log(`Jar Set!`)

      // Set Strategy
      await executeTx(callAttempts, 'setStratTx', Controller.setStrategy, txRefs['want'], txRefs['strategy'].address);
      console.log(`Strategy Set!`)
      console.log(`✔️ Controller params all set!`);

      // Deposit Want
      console.log(`Depositing in Jar...`);
      await executeTx(callAttempts, 'depositTx', txRefs['jar'].depositAll)
      console.log(`✔️ Successfully deposited want in Jar`);

      // Call Earn
      console.log(`Calling earn...`);
      await executeTx(callAttempts, 'earnTx', txRefs['jar'].earn);
      console.log(`✔️ Successfully called earn`);

      // Call Harvest
      console.log(`Waiting for 30 seconds before harvesting...`);
      await sleep(30000);
      await executeTx(callAttempts, 'harvestTx', txRefs['strategy'].harvest);

      txRefs['ratio'] = await txRefs['jar'].getRatio();

      if (txRefs['ratio'].gt(BigNumber.from(parseEther("1")))) {
        console.log(`✔️ Harvest was successful, ending ratio of ${txRefs['ratio'].toString()}`);
        testedStrategies.push(txRefs['strategy'].address)
      } else {
        console.log(`❌ Harvest failed, ending ratio of ${txRefs['ratio'].toString()}`);
      }
      // Script Report
      const report =
        `
      Jar Info -
      name: ${txRefs['name']}
      want: ${txRefs['want']}
      picklejar: ${txRefs['jar'].address}
      strategy: ${txRefs['strategy'].address}
      ratio: ${txRefs['ratio'].toString()}
      `;

      console.log(txRefs);
      // console.log(report);

      allReports.push(report);
    } catch (e) {
      console.log(`Oops something went wrong...`);
      console.error(e);
    }
  }
  console.log(
    `
    ----------------------------
      Here's the full report -
    ----------------------------
    ${allReports.join('\n')}
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    (>'-')> <('-'<) ^('-')^ v('-')v
    '''''''''''''''''''''''''''''
    `
  );
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

