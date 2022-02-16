require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
const {removeConsoleLog} = require("hardhat-preprocessor");
require("dotenv").config();

module.exports = {
  defaultNetwork: "hardhat",
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
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/hryDcEe1YR3iSfKm1pZWyi5RwiUUznMX`,
      },
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      allowUnlimitedContractSize: true,
      hardfork: "london",
      gasPrice: "auto",
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      hardfork: "london",
      gasPrice: "auto",
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [`0x${process.env.MNEMONIC}`],
      hardfork: "london",
      gasPrice: "auto",
    },
    matic: {
      url: "https://polygon-rpc.com/",
      accounts: [`0x${process.env.MNEMONIC}`],
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_APIKEY,
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
    gasPrice: 89,
  },
  preprocess: {
    eachLine: removeConsoleLog((hre) => hre.network.name !== "hardhat" && hre.network.name !== "localhost"),
  },
  mocha: {
    timeout: 200000000,
  },
  vyper: {
    version: "0.2.7",
  },
};
