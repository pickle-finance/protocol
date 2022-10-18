import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-vyper";
import "hardhat-deploy";
import "hardhat-contract-sizer";
import { removeConsoleLog } from "hardhat-preprocessor";
import { HardhatUserConfig } from "hardhat/config";
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
        //        blockNumber: 16149920,
      },
      // accounts: {
      //   mnemonic: process.env.MNEMONIC,
      // },
      accounts: [
        {
          privateKey: process.env.PRIVATE_KEY || "",
          balance: "1000000000000000000000",
        },
      ],
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
      url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.INFURA_KEY}`,
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

export default config;
