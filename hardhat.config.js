require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.6.7",
  hardhat: {
    forking: {
      url:
        "https://eth-mainnet.alchemyapi.io/v2/C4ZFV1uFaAaDsJB8v_dSSCOFFjbnfgtB",
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
