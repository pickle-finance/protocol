const {BigNumber} = require("ethers");
const {parseEther} = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const txRefsJson = require("../deployments/fantom/txRefs.json");

// Script configs
const sleepToggle = true;
const sleepTime = 15000;
const callAttempts = 3;

// References
const txRefs = txRefsJson;
const allReports = [];

// Addresses & Contracts
const governance = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";
const strategist = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";
const controller = "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6";
const timelock = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";

const contracts = [
  "src/strategies/fantom/beethovenx/strategy-beethovenx-ftm-beets.sol:StrategyBeethovenFtmBeetsLp",
  // "src/strategies/fantom/beethovenx/strategy-beethovenx-ftm-btc-eth.sol:StrategyBeethovenFtmBtcEthLp",
  // "src/strategies/fantom/beethovenx/strategy-beethovenx-lqdr-ftm.sol:StrategyBeethovenLqdrFtmLp",
  // "src/strategies/fantom/beethovenx/strategy-beethovenx-usdc-dai-mai.sol:StrategyBeethovenUsdcDaiMaiLp",
  // "src/strategies/fantom/beethovenx/strategy-beethovenx-usdc-ftm-btc-eth.sol:StrategyBeethovenUsdcFtmBtcEthLp",
  // "src/strategies/fantom/beethovenx/strategy-beethovenx-wftm-matic-sol-avax-luna-bnb.sold:StrategyBeethovenWftmMaticSolAvaxLunaBnbLp",
  // "src/strategies/fantom/beethovenx/strategy-beethovenx-wftm-usdc.sol:StrategyBeethovenWftmUsdcLp",
];

const testedStratsAddresses = [];
const testedStratsContracts = [];

// Functions
const sleep = async (ms, active = true) => {
  if (active) {
    console.log("Sleeping...");
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
};

const verifyContracts = async () => {
  console.log(`Verifying contracts...`);
  await Promise.all(
    testedStratsAddresses.map(async (address, idx) => {
      try {
        await hre.run("verify:verify", {
          contract: testedStratsContracts[idx],
          address: address,
          constructorArguments: [governance, strategist, controller, timelock],
        });
      } catch (e) {
        console.error(e);
      }
    })
  );
};

const deployAndTest = async () => {
  const executeTx = async (calls, fn, ...args) => {
    try {
      const txn = await fn(...args);
      await txn.wait();
      return txn;
    } catch (e) {
      console.error(e);
      if (calls > 0) {
        console.log(`Trying again. ${calls} more attempts left.`);
        await sleep(sleepTime, sleepToggle);
        return await executeTx(calls - 1, fn, ...args);
      } else {
        console.log("Looks like something is broken!");
        return undefined;
      }
    }
  };

  for (const contract of contracts) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);
    const name = contract.substring(contract.lastIndexOf(":") + 1);
    txRefs[name] = {name: name};

    try {
      if (!txRefs[name].strategy) {
        // Deploy Strategy contract
        console.log(`Deploying ${name}...`);
        const strategy = await executeTx(
          callAttempts,
          StrategyFactory.deploy,
          governance,
          strategist,
          controller,
          timelock
        );
        txRefs[name].strategy = strategy;
      }

      if (txRefs[name].strategy && !txRefs[name].jar) {
        //TODO: Add check to pass of done before.
        console.log(`✔️ Strategy deployed at: ${txRefs[name].strategy.address}`);

        // Get Want
        txRefs[name].want = await txRefs[name].strategy.want();

        // Deploy PickleJar contract
        const jar = await executeTx(
          callAttempts,
          PickleJarFactory.deploy,
          txRefs[name].want,
          governance,
          timelock,
          controller
        );
        txRefs[name].jar = jar;
      }

      if (txRefs[name].jar && !txRefs[name].wantApprove) {
        console.log(`✔️ PickleJar deployed at: ${txRefs[name].jar.address}`);

        // Log Want
        console.log(`Want address is: ${txRefs[name].want}`);
        console.log(`Approving want token for deposit...`);
        const wantContract = await ethers.getContractAt("ERC20", txRefs[name].want);

        // Approve Want
        const approveTx = await executeTx(
          callAttempts,
          wantContract.approve,
          txRefs[name].jar.address,
          ethers.constants.MaxUint256
        );
        txRefs[name].wantApprove = approveTx;
      }

      if (txRefs[name].wantApprove && !txRefs[name].stratApproveTx) {
        console.log(`✔️ Successfully approved Jar to spend want`);
        console.log(`Setting all the necessary stuff in controller...`);

        // Approve Strategy
        const approveStratTx = await executeTx(
          callAttempts,
          Controller.approveStrategy,
          txRefs[name].want,
          txRefs[name].strategy.address
        );
        txRefs[name].stratApproveTx = approveStratTx;
      }

      if (txRefs[name].stratApproveTx && !txRefs[name].jarSetTx) {
        console.log(`Strategy Approved!`);

        // Set Jar
        const setJarTx = await executeTx(callAttempts, Controller.setJar, txRefs[name].want, txRefs[name].jar.address);
        txRefs[name].jarSetTx = setJarTx;
      }

      if (txRefs[name].jarSetTx && !txRefs[name].stratSetTx) {
        console.log(`Jar Set!`);

        // Set Strategy
        const setStratTx = await executeTx(
          callAttempts,
          Controller.setStrategy,
          txRefs[name].want,
          txRefs[name].strategy.address
        );
        txRefs[name].stratSetTx = setStratTx;
      }

      if (txRefs[name].stratSetTx && !txRefs[name].depositTx) {
        console.log(`Strategy Set!`);
        console.log(`✔️ Controller params all set!`);

        // Deposit Want
        console.log(`Depositing in Jar...`);
        const depositTx = await executeTx(callAttempts, txRefs[name].jar.depositAll);
        txRefs[name].depositTx = depositTx;
      }

      if (txRefs[name].depositTx && !txRefs[name].earnTx) {
        console.log(`✔️ Successfully deposited want in Jar`);

        // Call Earn
        console.log(`Calling earn...`);
        const earnTx = await executeTx(callAttempts, txRefs[name].jar.earn);
        txRefs[name].earnTx = earnTx;
      }

      if (txRefs[name].earnTx && !txRefs[name].harvestTx) {
        console.log(`✔️ Successfully called earn`);

        // Call Harvest
        console.log(`Waiting for 60 seconds before harvesting...`);
        await sleep(60000);
        const harvestTx = await executeTx(callAttempts, txRefs[name].strategy.harvest);

        const ratio = await txRefs[name].jar.getRatio();

        if (ratio.gt(BigNumber.from(parseEther("1")))) {
          console.log(`✔️ Harvest was successful, ending ratio of ${ratio.toString()}`);
          testedStratsAddresses.push(txRefs[name].strategy.address);
          testedStratsContracts.push(contract);
        } else {
          console.log(`❌ Harvest failed, ending ratio of ${txRefs[ratio].toString()}`);
        }
        txRefs[name].harvestTx = harvestTx;
        txRefs[name].ratio = ratio;
      }

      // console.log(txRefs);
      // console.log(report);
    } catch (e) {
      console.log(`Oops something went wrong...`);
      console.error(e);
    }

    // Script Report
    const report = `
    ${txRefs[name].name}
    jar:\t\t\t${txRefs[name].jar?.address}
    want:\t\t\t${txRefs[name].want}
    strategy:\t${txRefs[name].strategy?.address}
    ----------------------------
    `;

    allReports.push(report);
  }

  console.log(
    `
    ----------------------------
      Here's the full report -
    ----------------------------
    ${allReports.join("\n")}
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    (>'-')> <('-'<) ^('-')^ v('-')v
    '''''''''''''''''''''''''''''
    `
  );

  fs.writeFile("../deployments/fantom/txRefs.json", JSON.stringify(txRefs, null, 4), (err) => {
    if (err) console.log(err);
  });
  fs.writeFile("../deployments/fantom/reports.json", JSON.stringify(allReports, null, 4), (err) => {
    if (err) console.log(err);
  });
};

const main = async () => {
  await deployAndTest();
  await verifyContracts();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
