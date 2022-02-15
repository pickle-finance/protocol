import { HardhatUserConfig } from 'hardhat/types';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-etherscan';
import "hardhat-deploy";
import '@typechain/hardhat';
import './tasks/accounts';

require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
    namedAccounts: {
        deployer: 0,
    },
    networks: {
        hardhat: {
            chainId: 43114,
            forking: {
                // url: "https://node.snowapi.net/ext/bc/C/rpc",
                url: "https://api.avax.network/ext/bc/C/rpc"
            },
        },
        fuji: {
            url: "https://api.avax-test.network/ext/bc/C/rpc",
            accounts: [process.env.PRIVATE_KEY ?? '']
        },
        avalanche: {
            chainId: 43114,
            url: "https://api.avax.network/ext/bc/C/rpc",
            accounts: [process.env.PRIVATE_KEY ?? '']
        },
        mainnet: {
            chainId: 43114,
            url: "https://api.avax.network/ext/bc/C/rpc",
            accounts: [process.env.PRIVATE_KEY ?? '']
        },
    },
    etherscan: {
        // Your API key for Snowtrace
        apiKey: process.env.SNOWTRACE_KEY ?? '',
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
    paths: { 
        sources: "./contracts", 
        tests: "./test",
        cache: "./cache", 
        artifacts: "./artifacts"
      },
    typechain: {
        alwaysGenerateOverloads: true,
        outDir: 'typechain',
    },
    mocha: {
        timeout: 240000
    },
    // vyper: {
    //   version: "0.2.4",
    // },
};
export default config;
