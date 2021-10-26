require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      accounts: [{privateKey: process.env.PRIVATE_KEY, balance: "100000000000000000000000"}],
      chainId: 43114,
      forking: {
        url: "https://node.snowapi.net/ext/bc/C/rpc",
      },
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
    mainnet: {
      url: "https://node.snowapi.net/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
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
  }
};
