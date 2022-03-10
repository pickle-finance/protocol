const { verify } = require("crypto");
const { BigNumber } = require("ethers");
const { formatEther, parseEther } = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;
const { exec } = require("child_process");
const fs = require("fs");

// Script configs
const sleepToggle = true;
const sleepTime = 10000;
const callAttempts = 3;
const generatePfcore = true;

// Pf-core generation configs
const outputFolder = 'scripts/degenApeV3Outputs';

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
const pfcoreArgs = { chain: "aurora", protocols: ["trisolaris"], extraTags: [], liquidityURL: "https://www.trisolaris.io/#/pool", rewardTokens: ["tri"], jarCode: "1ab", farmAddress: "", componentNames: [], componentAddresses: [] };

// References
let txRefs = {};
const allTxRefs = [];
const allReports = [];

// Addresses & Contracts
const governance = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const strategist = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const controller = "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E";
const timelock = "0x4204FDD868FFe0e62F57e6A626F8C9530F7d5AD1";
const harvester = ["0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf"];

const contracts = [
  // "src/strategies/near/trisolaris/strategoy-tri-$aurora-$near-lp.sol:StrategyTriAuroraNearLp",
  "src/strategies/near/trisolaris/strategy-tri-near-usdc-lp.sol:StrategyTriNearUsdcLp",
  // "src/strategies/near/trisolaris/strategy-tri-$near-$usdt-lp.sol:StrategyTriNearUsdtLp"
];

const testedStrategies = [
  "0xE197b88C0C94F6396a66f964dbd6F87F11EF95D4"
];

// Functions
const sleep = async (ms, active = true) => {
  if (active) {
    console.log("Sleeping...")
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
};

// Use this for verification of 5 contracts or less
const fastVerifyContracts = async (strategies) => {
  // await exec("npx hardhat clean");
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

// Use this for verificationof 5 contracts or more
const slowVerifyContracts = async (strategies) => {
  for (strategy of strategies) {
    try {
      await hre.run("verify:verify", {
        address: strategy,
        constructorArguments: [governance, strategist, controller, timelock],
      });
    } catch (e) {
      console.error(e);
    }
  }
}

const executeTx = async (calls, tx, fn, ...args) => {
  await sleep(sleepTime, sleepToggle);
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
  await sleep(sleepTime, sleepToggle);
}

const outputFolderSetup = async () => {
  try {
    if (!fs.existsSync(outputFolder)) {
      fs.mkdirSync(outputFolder)
    }
    if (!fs.existsSync(`${outputFolder}/jarsAndFarms.ts`)) {
      fs.closeSync(fs.openSync(`${outputFolder}/jarsAndFarms.ts`, 'a'))
    }
    if (!fs.existsSync(`${outputFolder}/implementations`)) {
      fs.mkdirSync(`${outputFolder}/implementations`)
    }
    if (!fs.existsSync(`${outputFolder}/implementations/${pfcoreArgs.chain}`)) {
      fs.mkdirSync(`${outputFolder}/implementations/${pfcoreArgs.chain}`)
    }
    if (!fs.existsSync(`${outputFolder}/jarBehaviorDiscovery`)) {
      fs.mkdirSync(`${outputFolder}/jarBehaviorDiscovery`)
    }
    if (!fs.existsSync(`${outputFolder}/jarBehaviorDiscovery/modelImports.ts`)) {
      fs.closeSync(fs.openSync(`${outputFolder}/jarBehaviorDiscovery/modelImports.ts`, 'a'))
    }
    if (!fs.existsSync(`${outputFolder}/jarBehaviorDiscovery/implImports.ts`)) {
      fs.closeSync(fs.openSync(`${outputFolder}/jarBehaviorDiscovery/implImports.ts`, 'a'))
    }
    if (!fs.existsSync(`${outputFolder}/jarBehaviorDiscovery/jarToBehaviorSet.ts`)) {
      fs.closeSync(fs.openSync(`${outputFolder}/jarBehaviorDiscovery/jarToBehaviorSet.ts`, 'a'))
    }
  } catch (err) {
    console.error(err)
  }
}

const incrementJar = async (jarCode, index) => {
  const nextLetter = letter => {
    let charCode = letter.charCodeAt(0);
    return String.fromCharCode((charCode - 96) % 26 + 97)
  };
  const lastLetter = jarCode.split('').pop();
  if (lastLetter === 'z') {
    pfcoreArgs.jarCode = jarCode.split('').slice(0, jarCode.length - 1).concat(nextLetter(lastLetter)).join('');
    pfcoreArgs.jarCode += "a";
  } else if (index != 0) {
    pfcoreArgs.jarCode = jarCode.split('').slice(0, jarCode.length - 1).concat(nextLetter(lastLetter)).join('')
  }
};

const generateJarBehaviorDiscovery = async (args) => {
  const modelImport = `${args.protocols.map(x => x.toUpperCase()).join('_')}_${args.componentNames.map(x => x.toUpperCase()).join('_')};
  `
  const implImport = `import { ${args.protocols.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join('').concat(args.componentNames.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join(''))} } from './impl/${args.chain}-${args.protocols.join('-')}-${args.componentNames.join('-')}';
  `;
  const jarToBehaviorSetImport = `jarToBehavior.set(${modelImport}.id, new ${args.protocols.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join('').concat(args.componentNames.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join(''))}());
  `;

  const modelImportsFilePath = `${outputFolder}/jarBehaviorDiscovery/modelImports.ts`;
  const implImportsFilePath = `${outputFolder}/jarBehaviorDiscovery/implImports.ts`;
  const jarToBehaviorSetFilePath = `${outputFolder}/jarBehaviorDiscovery/jarToBehaviorSet.ts`;

  try {
    if (fs.existsSync(modelImportsFilePath)) {
      fs.appendFileSync(modelImportsFilePath, modelImport, err => {
        if (err) {
          console.error(err)
          return
        }
      });
    }
  } catch (err) {
    console.error(err)
  }

  try {
    if (fs.existsSync(implImportsFilePath)) {
      fs.appendFileSync(implImportsFilePath, implImport, err => {
        if (err) {
          console.error(err)
          return
        }
      });
    }
  } catch (err) {
    console.error(err)
  }

  try {
    if (fs.existsSync(jarToBehaviorSetFilePath)) {
      fs.appendFileSync(jarToBehaviorSetFilePath, jarToBehaviorSetImport, err => {
        if (err) {
          console.error(err)
          return
        }
      });
    }
  } catch (err) {
    console.error(err)
  }
}


const generateJarsAndFarms = async (args, jarAddress, jarStartBlock, wantAddress, controller) => {
  // depositTokenLink is the only string manipulation likely to change for
  // different protocols.
  const depositTokenLink = `${args.liquidityURL}${args.componentAddresses.join('/')}`
  ////////////////////////

  const jarName = `${args.chain.toUpperCase()}_${args.protocols.map(x => x.toUpperCase()).join('_')}_${args.componentNames.map(x => x.toUpperCase()).join('_')}`
  const jarKey = `${args.protocols.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join('')}LP ${args.componentNames.map(x => x.toUpperCase()).join('/')}`

  const id = `${args.chain}Jar ${args.jarCode}`
  const rewardTokens = `${args.rewardTokens.join('", "')}`
  const depositTokenName = `${args.protocols.map(x => x.toUpperCase()).join('_')}_${args.componentNames.map(x => x.toUpperCase()).join('_')}`
  const depositTokenComponents = `${args.componentNames.join('", "')}`
  const chainNetwork = `${args.chain.slice(0, 1).toUpperCase().concat(args.chain.slice(1))}`;
  const assetProtocol = `${args.protocols[0].toUpperCase()}`
  const apiKey = `${args.protocols.map(x => x.toUpperCase()).join('')}LP-${args.componentNames.map(x => x.toUpperCase()).join('-')}`;
  const farm = args.farmAddress ? `"${args.farmAddress}"` : "NULL_ADDRESS";

  const output = `
export const JAR_${jarName}_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "${id}",
        contract: "${jarAddress}",
        startBlock: ${jarStartBlock},
        depositToken: {
          addr: "${wantAddress}",
          name: "${jarKey}",
          link: "${depositTokenLink}${wantAddress}",
          components: ["${depositTokenComponents}"],
        },
        rewardTokens: ["${rewardTokens}"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.${chainNetwork},
        protocol: AssetProtocol.${assetProtocol},
        details: {
          apiKey: "${apiKey}",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "${controller}"
        },
        farm: {
          farmAddress: ${farm},
          farmNickname: "p${jarKey}",
          farmDepositTokenName: "p${jarKey}",
        },
    };
    JAR_DEFINITIONS.push(JAR_${jarName}_LP);
    `
  const filePath = `${outputFolder}/jarsAndFarms.ts`

  try {
    if (fs.existsSync(filePath)) {
      fs.appendFileSync(filePath, output, err => {
        if (err) {
          console.error(err)
          return
        }
      });
    }
  } catch (err) {
    console.error(err)
  }
  console.log(output)
}

const generateImplementations = async (args) => {
  const jarProtocols = args.protocols.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join('');
  const jarComponents = args.componentNames.map(x => x.slice(0, 1).toUpperCase().concat(x.slice(1))).join('');

  const output = `
import { ${jarProtocols}${jarComponents}Jar } from "./${args.chain}-${args.protocols.join('-')}${args.componentNames.join('-')}-jar";
export class ${jarProtocols}${jarComponents} extends ${jarProtocols}Jar {
  constructor() {
    super();
  }
}
  `
  const filePath = `${outputFolder}/implementations/${pfcoreArgs.chain}/${pfcoreArgs.chain}-${pfcoreArgs.protocols.join('-')}-${pfcoreArgs.extraTags.join('-')}-${pfcoreArgs.componentNames.join('-')}.ts`;

  if (!fs.existsSync(filePath)) {
    try {
      fs.writeFileSync(filePath, output)
    } catch (err) {
      console.error(err)
    }
  }
  console.log(output)

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
      await sleep(sleepTime, sleepToggle);
      txRefs['want'] = await txRefs['strategy'].want();

      // Deploy PickleJar contract
      await executeTx(callAttempts, 'jar', PickleJarFactory.deploy.bind(PickleJarFactory), txRefs['want'], governance, timelock, controller);
      console.log(`✔️ PickleJar deployed at: ${txRefs['jar'].address} `);

      // Log Want
      console.log(`Want address is: ${txRefs['want']} `);
      console.log(`Approving want token for deposit...`);
      await sleep(sleepTime, sleepToggle);
      txRefs['wantContract'] = await ethers.getContractAt("ERC20", txRefs['want']);

      // Approve Want
      await executeTx(callAttempts, 'approveTx', txRefs['wantContract'].approve, txRefs['jar'].address, ethers.constants.MaxUint256);
      console.log(`✔️ Successfully approved Jar to spend want`);
      console.log(`Setting all the necessary stuff in controller...`);

      // Approve Strategy
      await executeTx(callAttempts, 'approveStratTx', Controller.approveStrategy, txRefs['want'], txRefs['strategy'].address);
      console.log(`Strategy Approved!`);

      // Set Jar
      await executeTx(callAttempts, 'setJarTx', Controller.setJar, txRefs['want'], txRefs['jar'].address);
      console.log(`Jar Set!`);

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
      console.log(`Waiting for ${sleepTime * 4 / 1000} seconds before harvesting...`);
      await sleep(sleepTime * 4);
      await executeTx(callAttempts, 'harvestTx', txRefs['strategy'].harvest);

      await sleep(sleepTime, sleepToggle);
      txRefs['ratio'] = await txRefs['jar'].getRatio();

      if (txRefs['ratio'].gt(BigNumber.from(parseEther("1")))) {
        console.log(`✔️ Harvest was successful, ending ratio of ${txRefs['ratio'].toString()} `);
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