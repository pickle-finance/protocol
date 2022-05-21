

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
const { removeConsoleLog } = require("hardhat-preprocessor");
require("dotenv").config();


module.exports = {
  defaultNetwork: "aurora",
  solidity: {
    compilers: [
      {
        version: "0.6.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://ftmrpc.ultimatenodes.io/`,
      },
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      hardfork: "london",
      gasPrice: "auto",
      gas: 2500000,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [`0x${process.env.MNEMONIC}`],
    },
    matic: {
      url: "https://polygon-rpc.com/",
      accounts: [`0x${process.env.MNEMONIC}`],
    },
    arbitrum: {
      url: `https://arb1.arbitrum.io/rpc/`,
      accounts: [`0x${process.env.MNEMONIC}`],
    },
    metis: {
      url: `https://andromeda.metis.io/?owner=1088`,
      accounts: [`0x${process.env.MNEMONIC}`],
    },
    moonbeam: {
      url: `https://rpc.api.moonbeam.network`,
      accounts: [`0x${process.env.MNEMONIC}`]
    },
    fantom: {
      url: `https://rpc.ftm.tools/`,
      accounts: [`0x${process.env.MNEMONIC}`],
      // gas: 40000000
    },
    aurora: {
      url: `https://mainnet.aurora.dev/`,
      accounts: [`0x${process.env.MNEMONIC}`],
    },
    xdai: {
      url: `https://rpc.xdaichain.com/`,
      accounts: [`0x${process.env.MNEMONIC}`],
      gasPrice: 10000000000,
    },
    optimism: {
      url: `https://mainnet.optimism.io`,
      accounts: [`0x${process.env.MNEMONIC}`],
    }
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
  },
  etherscan: {
    apiKey: {
      mainnet: `${process.env.ETHERSCAN_APIKEY}`,
      aurora: `${process.env.AURORASCAN_APIKEY}`,
      xdai: `${process.env.GNOSIS_APIKEY}`,
    },
  },
  paths: {
    sources: "./src",
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
    eachLine: removeConsoleLog((hre) => hre.network.name !== "hardhat" && hre.network.name !== "localhost"),
  },
  mocha: {
    timeout: 20000000,
  },
  vyper: {
    version: "0.2.7",
  },
};