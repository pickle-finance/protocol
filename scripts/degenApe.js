const {verify} = require("crypto");
const {BigNumber} = require("ethers");
const {formatEther, parseEther} = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const {
  outputFolderSetup,
  incrementJar,
  generateJarBehaviorDiscovery,
  generateJarsAndFarms,
  generateImplementations,
} = require("./pfcoreUtils.js");
const {sleep, fastVerifyContracts, slowVerifyContracts} = require("./degenUtils.js");

// Script configs
const sleepConfig = {sleepToggle: true, sleepTime: 10000};
const callAttempts = 3;
const generatePfcore = true;

// Pf-core generation configs
const outputFolder = "scripts/degenApe/degenApeOutputs";

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
const pfcoreArgs = {
  chain: "optimism",
  protocols: ["zipswap"],
  extraTags: [],
  liquidityURL: "https://zipswap.fi/#/add/",
  rewardTokens: ["zip", "gohm"],
  jarCode: "1e",
  farmAddress: "",
  componentNames: [],
  componentAddresses: [],
};

// Addresses & Contracts
const governance = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const strategist = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const controller = "0xe5E231De20C68AabB8D669f87971aE57E2AbF680";
const timelock = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const harvester = ["0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf"];

const contracts = ["src/strategies/gnosis/curve/strategy-curve-3pool-lp.sol:StrategyXdaiCurve3CRV"];

const testedStrategies = [];

const executeTx = async (calls, fn, ...args) => {
  await sleep(sleepConfig);
  try {
    const transaction = await fn(...args);

    // If deployTransaction property is empty, call normal wait()
    if (transaction.deployTransaction) {
      await transaction.deployTransaction.wait();
    } else {
      await transaction.wait();
    }
  } catch (e) {
    console.error(e);
    if (calls > 0) {
      console.log(`Trying again. ${calls} more attempts left.`);
      await executeTx(calls - 1, fn, ...args);
    } else {
      console.log("Looks like something is broken!");
      return Error;
    }
  }
};

const deployContractsAndGeneratePfcore = async () => {
  // References
  const allReports = [];
  for (const [jarIndex, contract] of contracts.entries()) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);
    const name = contract.substring(contract.lastIndexOf(":") + 1);

    try {
      // Deploy Strategy contract
      console.log(`Deploying ${name}...`);
      const strategy = await executeTx(
        callAttempts,
        StrategyFactory.deploy.bind(StrategyFactory),
        governance,
        strategist,
        controller,
        timelock
      );
      console.log(`✔️ Strategy deployed at: ${strategy.address} `);

      // Get Want
      await sleep(sleepConfig);
      const want = await strategy.want();

      // Log Want
      console.log(`Want address is: ${want} `);
      await sleep(sleepConfig);
      const wantContract = await ethers.getContractAt("ERC20", want);

      // Check if Want already has a Jar on Controller
      await sleep(sleepConfig);
      const currentControllerJar = await Controller.jars(want);

      // Only do shit if there's not already an active jar
      if (currentControllerJar === ethers.constants.AddressZero) {
        // Deploy PickleJar contract
        const jar = await executeTx(
          callAttempts,
          PickleJarFactory.deploy.bind(PickleJarFactory),
          want,
          governance,
          timelock,
          controller
        );
        console.log(`✔️ PickleJar deployed at: ${jar.address} `);

        // Set Jar
        await executeTx(callAttempts, Controller.setJar, want, jar.address);
        console.log(`Jar Set!`);
      } else {
        console.log(`Jar for this want already exists`);
      }

      // Approve Want
      console.log(`Approving want token for deposit...`);
      await executeTx(callAttempts, wantContract.approve, jar.address, ethers.constants.MaxUint256);
      console.log(`✔️ Successfully approved Jar to spend want`);

      // Approve Strategy
      await executeTx(callAttempts, Controller.approveStrategy, want, strategy.address);
      console.log(`Strategy Approved!`);

      // Set Strategy
      await executeTx(callAttempts, Controller.setStrategy, want, strategy.address);
      console.log(`Strategy Set!`);
      console.log(`✔️ Controller params all set!`);

      // Deposit Want
      console.log(`Depositing in Jar...`);
      await executeTx(callAttempts, jar.depositAll);
      console.log(`✔️ Successfully deposited want in Jar`);

      // Call Earn
      console.log(`Calling earn...`);
      await executeTx(callAttempts, jar.earn);
      console.log(`✔️ Successfully called earn`);

      //Push Strategy to be verified
      testedStrategies.push(strategy.address);

      // Call Harvest
      console.log(`Waiting for ${(sleepConfig.sleepTime * 4) / 1000} seconds before harvesting...`);
      await sleep({
        ...sleepConfig,
        sleepTime: sleepConfig.sleepTime * 4,
      });
      await executeTx(callAttempts, strategy.harvest);

      await sleep(sleepConfig);
      const ratio = await jar.getRatio();

      if (ratio.gt(BigNumber.from(parseEther("1")))) {
        console.log(`✔️ Harvest was successful, ending ratio of ${ratio.toString()} `);

        //Pf-core Generation
        if (generatePfcore) {
          // Regex targets all items that start with $ and end with -
          const regex = /(?<=\$).*?(?=-)/g;
          pfcoreArgs.componentNames = contract.match(regex);

          // pfcoreArgs.componentNames.forEach((x, i) => {
          //   const token = await txRefs['want'].getToken(i);
          //   pfcoreArgs.componentAddresses.push(token);
          // });

          await outputFolderSetup();
          await incrementJar(pfcoreArgs.jarCode, jarIndex);
          await generateJarBehaviorDiscovery(pfcoreArgs);
          await generateJarsAndFarms(pfcoreArgs, jar.address, jar.blockNumber, want, controller);
          await generateImplementations(pfcoreArgs);
        }
      } else {
        console.log(`❌ Harvest failed, ending ratio of ${ratio.toString()} `);
      }

      console.log(`Whitelisting harvester at ${harvester} `);
      const whitelistHarvestersTx = await executeTx(callAttempts, strategy.whitelistHarvesters, harvester);

      // Script Report
      const report = `
Jar Info -
name: ${name}
want: ${want}
picklejar: ${jar.address}
strategy: ${strategy.address}
controller: ${controller}
ratio: ${ratio.toString()}
`;
      console.log(report);
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
      ${allReports.join("\n")}
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      (> '-') > < ('-' <) ^ ('-') ^ v('-')v
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
