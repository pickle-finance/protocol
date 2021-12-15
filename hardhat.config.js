require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      accounts: [{ privateKey: process.env.PRIVATE_KEY, balance: "100000000000000000000000" }],
      chainId: 43114,
      forking: {
        // url: "https://node.snowapi.net/ext/bc/C/rpc",
        url: "https://api.avax.network/ext/bc/C/rpc"
      },
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
    mainnet: {
      chainId: 43114,
      url: "https://api.avax.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
    AVALANCHE: {
      chainId: 43114,
      url: "https://api.avax.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  etherscan: {
    // Your API key for Snowtrace
    apiKey: process.env.SNOWTRACE_KEY,
  },
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
    ],
  },
  mocha: {
    timeout: 120000
  },
  paths: {
    sources:"./contracts/AxialRouter.sol"
  },
  // vyper: {
  //   version: "0.2.4",
  // },
};