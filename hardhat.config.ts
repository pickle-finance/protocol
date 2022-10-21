import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-vyper";
import "hardhat-deploy";
import "hardhat-contract-sizer";
import { removeConsoleLog } from "hardhat-preprocessor";
import { HardhatUserConfig, subtask, task, types } from "hardhat/config";
import fs from "fs";
import * as dotenv from "dotenv";
dotenv.config();

const defaultCompilerSettings = {
  optimizer: {
    enabled: true,
    runs: 200,
  },
};

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.6.7",
        settings: defaultCompilerSettings,
      },
      {
        version: "0.6.12",
        settings: defaultCompilerSettings,
      },
      {
        version: "0.8.16",
        settings: defaultCompilerSettings,
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://arbitrum-mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
        ignoreUnknownTxType: true, // needed to work with patched Hardhat + Arbitrum Nitro
        //        blockNumber: 16149920,
      },
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      // mining: {
      //   auto: false,
      //   interval: [4000, 6000],
      // },
      hardfork: "london",
      gasPrice: "auto",
      gas: 6500000,
    },
    mainnet: {
      // url: `https://rpc.flashbots.net`,
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 1,
    },
    matic: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_MATIC}`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 137,
    },
    arbitrumOne: {
      url: `https://1rpc.io/arb`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 42161,
    },
    metis: {
      url: `https://andromeda.metis.io/?owner=1088`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 1088,
    },
    moonbeam: {
      url: `https://rpc.api.moonbeam.network`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 1284,
    },
    moonriver: {
      url: `https://rpc.api.moonriver.moonbeam.network`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 1285,
    },
    opera: {
      url: `https://rpc.ftm.tools/`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 250,
    },
    aurora: {
      url: `https://mainnet.aurora.dev/`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 1313161554,
    },
    optimisticEthereum: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_OPTIMISM}`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 10,
    },
    gnosis: {
      url: "https://xdai-archive.blockscout.com",
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 100,
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_APIKEY ?? "",
      aurora: process.env.AURORASCAN_APIKEY ?? "",
      xdai: process.env.BLOCKSCOUT_APIKEY_GNOSIS ?? "",
      optimisticEthereum: process.env.ETHERSCAN_APIKEY_OPTIMISM ?? "",
      arbitrumOne: process.env.ETHERSCAN_APIKEY_ARBISCAN ?? "",
      opera: process.env.ETHERSCAN_APIKEY_FANTOM ?? "",
    },
  },
  paths: {
    sources: "./src/strategies/arbitrum",
    tests: "./src/tests/strategies",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  gasReporter: {
    enabled: true,
    coinmarketcap: process.env.COINMARKETCAP,
    currency: "USD",
    gasPrice: 32,
  },
  preprocess: {
    eachLine: removeConsoleLog(
      (hre) =>
        hre.network.name !== "hardhat" && hre.network.name !== "localhost"
    ),
  },
  mocha: {
    timeout: 20000000,
  },
  vyper: {
    compilers: [{ version: "0.2.4" }, { version: "0.2.7" }],
  },
};

function getSortedFiles(dependenciesGraph) {
  const tsort = require("tsort");
  const graph = tsort();

  const filesMap = {};
  const resolvedFiles = dependenciesGraph.getResolvedFiles();
  resolvedFiles.forEach((f) => (filesMap[f.sourceName] = f));

  for (const [from, deps] of dependenciesGraph.entries()) {
    for (const to of deps) {
      graph.add(to.sourceName, from.sourceName);
    }
  }

  const topologicalSortedNames = graph.sort();

  // If an entry has no dependency it won't be included in the graph, so we
  // add them and then dedup the array
  const withEntries = topologicalSortedNames.concat(
    resolvedFiles.map((f) => f.sourceName)
  );

  const sortedNames = [...new Set(withEntries)];
  return sortedNames.map((n: any) => filesMap[n]);
}

function getFileWithoutImports(resolvedFile) {
  const IMPORT_SOLIDITY_REGEX = /^\s*import(\s+)[\s\S]*?;\s*$/gm;

  return resolvedFile.content.rawContent
    .replace(IMPORT_SOLIDITY_REGEX, "")
    .trim();
}

subtask(
  "flat:get-flattened-sources",
  "Returns all contracts and their dependencies flattened"
)
  .addOptionalParam("files", undefined, undefined, types.any)
  .addOptionalParam("output", undefined, undefined, types.string)
  .setAction(async ({ files, output }, { run }) => {
    const dependencyGraph = await run("flat:get-dependency-graph", { files });
    console.log(dependencyGraph);

    let flattened = "";

    if (dependencyGraph.getResolvedFiles().length === 0) {
      return flattened;
    }

    const sortedFiles = getSortedFiles(dependencyGraph);

    let isFirst = true;
    for (const file of sortedFiles) {
      if (!isFirst) {
        flattened += "\n";
      }
      flattened += `// File ${file.getVersionedName()}\n`;
      flattened += `${getFileWithoutImports(file)}\n`;

      isFirst = false;
    }

    // Remove every line started with "// SPDX-License-Identifier:"
    flattened = flattened.replace(
      /SPDX-License-Identifier:/gm,
      "License-Identifier:"
    );

    flattened = `// SPDX-License-Identifier: MIXED\n\n${flattened}`;

    // Remove every line started with "pragma experimental ABIEncoderV2;" except the first one
    flattened = flattened.replace(
      /pragma experimental ABIEncoderV2;\n/gm,
      (
        (i) => (m) =>
          !i++ ? m : ""
      )(0)
    );

    flattened = flattened.trim();
    if (output) {
      console.log("Writing to", output);
      fs.writeFileSync(output, flattened);
      return "";
    }
    return flattened;
  });

subtask("flat:get-dependency-graph")
  .addOptionalParam("files", undefined, undefined, types.any)
  .setAction(async ({ files }, { run }) => {
    const sourcePaths =
      files === undefined
        ? await run("compile:solidity:get-source-paths")
        : files.map((f) => fs.realpathSync(f));

    const sourceNames = await run("compile:solidity:get-source-names", {
      sourcePaths,
    });

    const dependencyGraph = await run("compile:solidity:get-dependency-graph", {
      sourceNames,
    });

    return dependencyGraph;
  });

task("flat", "Flattens and prints contracts and their dependencies")
  .addOptionalVariadicPositionalParam(
    "files",
    "The files to flatten",
    undefined,
    types.inputFile
  )
  .addOptionalParam(
    "output",
    "Specify the output file",
    undefined,
    types.string
  )
  .setAction(async ({ files, output }, { run }) => {
    console.log(
      await run("flat:get-flattened-sources", {
        files,
        output,
      })
    );
  });

export default config;
