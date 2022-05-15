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

module.exports = { generateImplementations, generateJarsAndFarms, outputFolderSetup, generateJarBehaviorDiscovery, incrementJar }