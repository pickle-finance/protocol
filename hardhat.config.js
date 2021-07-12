require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("hardhat-gas-reporter");
require("dotenv").config({});

const deployer = process.env.MNEMONIC;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
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
          evmVersion: "istanbul",
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: "istanbul",
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url:
          "https://eth-mainnet.alchemyapi.io/v2/C4ZFV1uFaAaDsJB8v_dSSCOFFjbnfgtB",
        blockNumber: 12807816,
      },
      timeout: 100000000,
    },
    mainnet: {
      url:
        "https://eth-mainnet.alchemyapi.io/v2/C4ZFV1uFaAaDsJB8v_dSSCOFFjbnfgtB",
      accounts: [deployer],
    },
    localhost: {
      chainId: 1337,
      url: "http://127.0.0.1:8545",
      timeout: 100000000,
    },
    matic: {
      chainId: 137,
      url: "https://rpc-mainnet.maticvigil.com/",
      accounts: [deployer],
    },
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
  mocha: {
    timeout: 2000000
  },
  vyper: {
    version: "0.2.7",
  },
};