const { verify } = require("crypto");
const { BigNumber } = require("ethers");
const { formatEther, parseEther } = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const { outputFolderSetup, incrementJar, generateJarBehaviorDiscovery, generateJarsAndFarms, generateImplementations } = require("./pfcoreUtils.js");
const { sleep, fastVerifyContracts, slowVerifyContracts } = require("./utils.js");

// Script configs
const sleepConfigs = { sleepToggle: true, sleepTime: 10000 }
const callAttempts = 3;
const generatePfcore = true;

// Pf-core generation configs
const outputFolder = 'scripts/degenApe/degenApeV3Outputs';

// These arguments need to be set manually before the script can make pf-core
// @param - chain: The chain on which the script is running
// @param - protocols: The first argument needs to be the main protocol. Additional
// protocols in reference to the underlying yield can also be added.
// @param - liquidityURL: This is the url from the underlying dex to provide users
// links to add liquidity.
// @param - rewardsToken: The rewardTokens that makeup the protocol yield.
// @param - jarCode: This is the first jar id that the script will deploy. The script will then iterate jarCode for each subsequent deployment.
// @param - farmAddress: The farm address for adding incentives to jars.
// @param - componentNames: The underlying tokens names of the lp. These will be added
// by the script from the strategy address.
// @param - componentAddresses: The underlying token addresses of the lp. These will be added
const pfcoreArgs = { chain: "gnosis", protocols: ["sushi"], extraTags: [], liquidityURL: "https://app.sushi.com/add/", rewardTokens: ["sushi", "gno"], jarCode: "1a", farmAddress: "", componentNames: [], componentAddresses: [] };

// References
let txRefs = {};
const allTxRefs = [];
const allReports = [];

// Addresses & Contracts
const governance = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const strategist = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const controller = "0xe5E231De20C68AabB8D669f87971aE57E2AbF680";
const timelock = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const harvester = ["0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf"];

const contracts = [
  "src/strategies/gnosis/curve/strategy-curve-3pool-lp.sol:StrategyXdaiCurve3CRV"
];

const testedStrategies = [
];

const executeTx = async (calls, tx, fn, ...args) => {
  await sleep(sleepConfigs);
  // if (!txRefs[tx]) { recall(executeTx, calls, tx, fn, ...args) }
  try {
    if (!txRefs[tx]) {
      txRefs[tx] = await fn(...args)
      if (tx === 'strategy') {
        await txRefs[tx].deployTransaction.wait();
      }
      else if (tx === 'jar') {
        const jarTx = await txRefs[tx].deployTransaction.wait();
        txRefs['jarStartBlock'] = jarTx.blockNumber;
      } else {
        await txRefs[tx].wait();
      }
    }
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
  await sleep(sleepConfigs);
}

const deployContractsAndGeneratePfcore = async () => {
  for (const [jarIndex, contract] of contracts.entries()) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);
    txRefs['name'] = contract.substring(contract.lastIndexOf(":") + 1);

    try {
      // Deploy Strategy contract
      console.log(`Deploying ${txRefs['name']}...`);
      await executeTx(callAttempts, 'strategy', StrategyFactory.deploy.bind(StrategyFactory), governance, strategist, controller, timelock);
      console.log(`✔️ Strategy deployed at: ${txRefs['strategy'].address} `);

      // Get Want
      await sleep(sleepConfigs);
      txRefs['want'] = await txRefs['strategy'].want();

      // Log Want
      console.log(`Want address is: ${txRefs['want']} `);
      await sleep(sleepConfigs);
      txRefs['wantContract'] = await ethers.getContractAt("ERC20", txRefs['want']);

      // Check if Want already has a Jar on Controller
      await sleep(sleepConfigs);
      txRefs['jar'] = await Controller.jars(txRefs['want']);

      if (!txRefs['jar']) {
        // Deploy PickleJar contract
        await executeTx(callAttempts, 'jar', PickleJarFactory.deploy.bind(PickleJarFactory), txRefs['want'], governance, timelock, controller);
        console.log(`✔️ PickleJar deployed at: ${txRefs['jar'].address} `);

        // Set Jar
        await executeTx(callAttempts, 'setJarTx', Controller.setJar, txRefs['want'], txRefs['jar'].address);
        console.log(`Jar Set!`);

        // Approve Want
        console.log(`Approving want token for deposit...`);
        await executeTx(callAttempts, 'approveTx', txRefs['wantContract'].approve, txRefs['jar'].address, ethers.constants.MaxUint256);
        console.log(`✔️ Successfully approved Jar to spend want`);
      } else {
        console.log(`Jar for this want already exists`);
      }

      // Approve Strategy
      await executeTx(callAttempts, 'approveStratTx', Controller.approveStrategy, txRefs['want'], txRefs['strategy'].address);
      console.log(`Strategy Approved!`);

      // Set Strategy
      await executeTx(callAttempts, 'setStratTx', Controller.setStrategy, txRefs['want'], txRefs['strategy'].address);
      console.log(`Strategy Set!`);
      console.log(`✔️ Controller params all set!`);

      // Deposit Want
      console.log(`Depositing in Jar...`);
      await executeTx(callAttempts, 'depositTx', txRefs['jar'].depositAll)
      console.log(`✔️ Successfully deposited want in Jar`);

      // Call Earn
      console.log(`Calling earn...`);
      await executeTx(callAttempts, 'earnTx', txRefs['jar'].earn);
      console.log(`✔️ Successfully called earn`);

      //Push Strategy to be verified
      testedStrategies.push(txRefs['strategy'].address)

      // Call Harvest
      console.log(`Waiting for ${sleepConfigs.sleepTime * 4 / 1000} seconds before harvesting...`);
      await sleep(sleepConfigs.sleepTime * 4);
      await executeTx(callAttempts, 'harvestTx', txRefs['strategy'].harvest);

      await sleep(sleepConfigs);
      txRefs['ratio'] = await txRefs['jar'].getRatio();

      if (txRefs['ratio'].gt(BigNumber.from(parseEther("1")))) {
        console.log(`✔️ Harvest was successful, ending ratio of ${txRefs['ratio'].toString()} `);

        //Pf-core Generation
        if (generatePfcore) {
          const regex = /(?<=\$).*?(?=-)/g;
          pfcoreArgs.componentNames = contract.match(regex);

          // pfcoreArgs.componentNames.forEach((x, i) => {
          //   const token = await txRefs['want'].getToken(i);
          //   pfcoreArgs.componentAddresses.push(token);
          // });

          await outputFolderSetup();
          await incrementJar(pfcoreArgs.jarCode, jarIndex);
          await generateJarBehaviorDiscovery(pfcoreArgs);
          await generateJarsAndFarms(pfcoreArgs, txRefs['jar'].address, txRefs['jarStartBlock'], txRefs['want'], controller);
          await generateImplementations(pfcoreArgs);
        }
      } else {
        console.log(`❌ Harvest failed, ending ratio of ${txRefs['ratio'].toString()} `);
      }

      console.log(`Whitelisting harvester at ${harvester}`);
      await executeTx(callAttempts, 'whitelistHarvestersTx', txRefs['strategy'].whitelistHarvesters, harvester);

      // Script Report
      const report =
        `
Jar Info -
name: ${txRefs['name']}
want: ${txRefs['want']}
picklejar: ${txRefs['jar'].address}
strategy: ${txRefs['strategy'].address}
controller: ${controller}
ratio: ${txRefs['ratio'].toString()}
`;
      console.log(report)
      allReports.push(report);

    } catch (e) {
      console.log(`Oops something went wrong...`);
      console.error(e);
    }
    allTxRefs.push(txRefs);
    txRefs = {};
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
  await deployContractsAndGeneratePfcore();
  // await fastVerifyContracts(testedStrategies);
  await slowVerifyContracts(testedStrategies);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });