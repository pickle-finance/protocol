
/*
  This script fetches all pool data for all pools from the GaugeProxyV2 contract, and updates the `pools.json` file and `error-pools.json` file.

  This includes the following for each pool:
  - Name
  - Platform
  - Type
  - Globe
  - Strategy
  - Gauge
  - Controller
  - Token Symbol
  - Token Address
  - Underlying Token Symbols (If Applicable)
  - Underlying Token Address (If Applicable)

  To run the script, simply use the following command after installing all dependencies with `npm i`:

  `node scripts/get-pools.js`
*/

// Imports:
const { ethers } = require('ethers');
const axios = require('axios');
const fs = require('fs');

// Setting Up RPCs:
const avax = new ethers.providers.JsonRpcProvider('https://api.avax.network/ext/bc/C/rpc');
const avax_backup = new ethers.providers.JsonRpcProvider('https://avax-mainnet.gateway.pokt.network/v1/lb/605238bf6b986eea7cf36d5e/ext/bc/C/rpc');

// Initializations:
const gaugeProxy = '0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27';
const ignoreAddresses = [
  '0xb91124ecef333f17354add2a8b944c76979fe3ec', // StableVault
  '0x53b37b9a6631c462d74d65d61e1c056ea9daa637'  // Weird PNG-ETH LP Token
];
const singleTraderJoeStrats = [
  '0x8c06828a1707b0322baaa46e3b0f4d1d55f6c3e6'  // xJOE
];
const lpSymbols = ['PGL', 'JLP'];
const axialSymbols = ['AS4D', 'AC4D', 'AM3D', 'AA3D'];
const zero = '0x0000000000000000000000000000000000000000';
const batchSize = 20;
let progress = 0;
let maxProgress = 0;
let erroredPools = [];

// ABIs:
const gaugeProxyABI = [
  { constant: true, inputs: [], name: "tokens", outputs: [{ name: "", type: "address[]" }], type: "function" },
  { constant: true, inputs: [{ name: "_token", type: "address" }], name: "getGauge", outputs: [{ name: "", type: "address" }], type: "function" }
];
const snowGlobeABI = [
  { constant: true, inputs: [], name: "controller", outputs: [{ name: "", type: "address" }], type: "function" },
  { constant: true, inputs: [], name: "token", outputs: [{ name: "", type: "address" }], type: "function" }
];
const controllerABI = [
  { constant: true, inputs: [{ name: "<input>", type: "address" }], name: "strategies", outputs: [{ name: "", type: "address" }], type: "function" }
];
const tokenABI = [
  { constant: true, inputs: [], name: "symbol", outputs: [{ name: "", type: "string" }], type: "function" }
];
const lpTokenABI = [
  { constant: true, inputs: [], name: "token0", outputs: [{ name: "", type: "address" }], type: "function" },
  { constant: true, inputs: [], name: "token1", outputs: [{ name: "", type: "address" }], type: "function" }
];
const strategyABI = [
  { constant: true, inputs: [], name: "getName", outputs: [{ name: "", type: "string" }], type: "function" }
]

/* ========================================================================================================================================================================= */

// Function to make blockchain queries:
const query = async (address, abi, method, args) => {
  let result;
  let errors = 0;
  while(!result) {
    try {
      let contract = new ethers.Contract(address, abi, avax);
      result = await contract[method](...args);
    } catch {
      try {
        let contract = new ethers.Contract(address, abi, avax_backup);
        result = await contract[method](...args);
      } catch {
        if(++errors === 5) {
          console.error(`\n  > Error calling ${method}(${args}) on ${address}`);
          console.warn(`  > Execution was stopped due to errors. Check script or try again.`);
          process.exit(1);
        }
      }
    }
  }
  return result;
}

/* ========================================================================================================================================================================= */

// Function to communicate script progress to user:
const updateProgress = () => {
  process.stdout.clearLine();
  process.stdout.cursorTo(0);
  if(++progress < maxProgress) {
    process.stdout.write(`  > Pools Loaded: ${progress}/${maxProgress}`);
  } else {
    process.stdout.write(`  > All ${maxProgress} Pools Loaded.\n`);
  }
}

/* ====================================================================================================================================================== */

// Function to write data to JSON file:
const writeJSON = (data, file) => {
  fs.writeFile(`./scripts/pool_results/${file}.json`, JSON.stringify(data, null, ' '), 'utf8', (err) => {
    if(err) {
      console.error(err);
    } else {
      console.info(`  > Successfully updated ${file}.json.`);
    }
  });
}

/* ====================================================================================================================================================== */

// Function to fetch pool data from API:
const fetchAPI = async () => {
  console.info(`  > Fetching API data...`);
  let url = 'https://api.snowapi.net/graphql';
  let method = 'post';
  let data = {query: 'query { SnowglobeContracts { pair, snowglobeAddress, gaugeAddress }}'};
  try {
    let pools = (await axios({url, method, data})).data.data.SnowglobeContracts;
    return pools;
  } catch {
    console.error(`  > Error fetching API data.`);
    console.warn(`  > Execution was stopped due to errors. Check script or try again.`);
    process.exit(1);
  }
}

/* ====================================================================================================================================================== */

// Function to fetch all SnowGlobe addresses:
const fetchGlobes = async () => {
  console.info(`  > Starting blockchain calls...`);
  let globes = await query(gaugeProxy, gaugeProxyABI, 'tokens', []);
  return globes;
}

/* ====================================================================================================================================================== */

// Function to fetch gauge address for a SnowGlobe:
const fetchGauge = async (globe) => {
  let strategy = await query(gaugeProxy, gaugeProxyABI, 'getGauge', [globe]);
  return strategy;
}

/* ====================================================================================================================================================== */

// Function to fetch controller address for a SnowGlobe:
const fetchController = async (globe) => {
  let controller = await query(globe, snowGlobeABI, 'controller', []);
  return controller;
}

/* ====================================================================================================================================================== */

// Function to fetch token address and symbol for a SnowGlobe:
const fetchToken = async (globe) => {
  let address = await query(globe, snowGlobeABI, 'token', []);
  let symbol = await query(address, tokenABI, 'symbol', []);
  return {symbol, address};
}

/* ====================================================================================================================================================== */

// Function to fetch strategy address for a SnowGlobe:
const fetchStrategy = async (controller, address) => {
  let strategy = await query(controller, controllerABI, 'strategies', [address]);
  return strategy;
}

/* ====================================================================================================================================================== */

// Function to fetch underlying token symbols and addresses for a SnowGlobe:
const fetchUnderlyingTokens = async (address) => {
  let token0 = await query(address, lpTokenABI, 'token0', []);
  let token1 = await query(address, lpTokenABI, 'token1', []);
  let symbol0 = await query(token0, tokenABI, 'symbol', []);
  let symbol1 = await query(token1, tokenABI, 'symbol', []);
  return {token0: {symbol: symbol0, address: token0}, token1: {symbol: symbol1, address: token1}};
}

/* ====================================================================================================================================================== */

// Function to fetch pool platform:
const fetchPlatform = async (token, strategy, globe) => {
  let platform = null;
  if(token.symbol === 'PGL') {
    platform = 'Pangolin';
  } else if(token.symbol === 'JLP' || singleTraderJoeStrats.includes(globe.toLowerCase())) {
    platform = 'Trader Joe';
  } else if(axialSymbols.includes(token.symbol)) {
    platform = 'Axial';
  } else {
    let name = (await query(strategy, strategyABI, 'getName', [])).slice(8);
    if(name.startsWith('Benqi')) {
      platform = 'Benqi';
    } else if(name.startsWith('Teddy')) {
      platform = 'Teddy';
    } else if(name.startsWith('Aave')) {
      platform = 'Aave';
    } else if(name.startsWith('Png')) {
      platform = 'Pangolin';
    } else if(name.startsWith('Joe')) {
      platform = 'Banker Joe';
    }
  }
  return platform;
}

/* ====================================================================================================================================================== */

// Function to fetch batch of data:
const fetchBatch = async (globes, apiPools) => {
  let data = [];
  let promises = globes.map(globe => (async () => {
    if(!ignoreAddresses.includes(globe.toLowerCase())) {
      let gauge = await fetchGauge(globe);
      if(gauge != zero) {
        let controller = await fetchController(globe);
        let token = await fetchToken(globe);
        let strategy = await fetchStrategy(controller, token.address);
        if(strategy != zero) {
          let apiPool = apiPools.find(pool => pool.snowglobeAddress.toLowerCase() === globe.toLowerCase());
          if(apiPool) {
            if(apiPool.gaugeAddress.toLowerCase() === gauge.toLowerCase()) {
              let platform = await fetchPlatform(token, strategy, globe);
              let type = lpSymbols.includes(token.symbol) ? 'lp' : 'single';
              if(type === 'lp') {
                let underlyingTokens = await fetchUnderlyingTokens(token.address);
                let name = '';
                if(underlyingTokens.token0.symbol === 'WAVAX') {
                  name = `AVAX-${underlyingTokens.token1.symbol}`;
                } else if(underlyingTokens.token1.symbol === 'WAVAX') {
                  name = `AVAX-${underlyingTokens.token0.symbol}`;
                } else {
                  name = `${underlyingTokens.token0.symbol}-${underlyingTokens.token1.symbol}`;
                }
                data.push({name, platform, type, globe, strategy, gauge, controller, token, underlyingTokens});
              } else {
                let name = token.symbol;
                data.push({name, platform, type, globe, strategy, gauge, controller, token});
              }
            } else {
              let error = 'Wrong Gauge on API';
              erroredPools.push({globe, strategy, gauge, controller, token, error});
            }
          } else {
            let error = 'Not on API (Should Probably be Deprecated)';
            erroredPools.push({globe, strategy, gauge, controller, token, error});
          }
        } else {
          let error = 'No Strategy';
          erroredPools.push({globe, strategy, gauge, controller, token, error});
        }
      }
    }
    updateProgress();
  })());
  await Promise.all(promises);
  return data;
}

/* ====================================================================================================================================================== */

// Function to fetch all data:
const fetch = async () => {

  // Initializations:
  let data = [];
  let apiData = [];
  let startBatch = 0;
  let endBatch = batchSize;

  // Fetching API Data:
  apiData.push(...(await fetchAPI()));

  // Fetching SnowGlobes:
  let globes = await fetchGlobes();
  maxProgress = globes.length;

  // Fetching Data:
  while(progress < maxProgress) {
    data.push(...(await fetchBatch(globes.slice(startBatch, endBatch), apiData)));
    startBatch += batchSize;
    endBatch += batchSize;
  }

  // Sorting Data:
  data.sort((a, b) => {
    if(a.type === 'lp') {
      if(b.type === 'lp') {
        let nameSort = a.name.localeCompare(b.name);
        if(nameSort === 0) {
          return a.globe.localeCompare(b.globe);
        } else {
          return nameSort;
        }
      } else {
        return -1;
      }
    } else if(b.type === 'lp') {
      return 1;
    } else {
      let nameSort = a.name.localeCompare(b.name);
      if(nameSort === 0) {
        return a.globe.localeCompare(b.globe);
      } else {
        return nameSort;
      }
    }
  });

  // JSON Output:
  writeJSON(data, 'pools');

  // Sorting Error Data:
  erroredPools.sort((a, b) => a.globe.localeCompare(b.globe));

  // Logging Errored Pools:
  writeJSON(erroredPools, 'error-pools');

}

/* ====================================================================================================================================================== */

// Fetching Data:
fetch();
