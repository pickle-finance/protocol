
/*

  This script fetches all pool data for all pools in the GaugeProxyV2 contract, and updates the `allPools.json` file.

  This includes:
  - SnowGlobe Address
  - Strategy Address
  - Gauge Address
  - Controller Address
  - Underlying Token Address

  To run the script, simply use the following command after installing all dependencies with `npm i`:

  `node scripts/get-pools.js`

*/

// Imports:
const { ethers } = require('ethers');
const fs = require('fs');

// Initializations:
const gaugeProxy = '0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27';
const rpcs = [
  'https://api.avax.network/ext/bc/C/rpc',
  'https://avax-mainnet.gateway.pokt.network/v1/lb/605238bf6b986eea7cf36d5e/ext/bc/C/rpc'
];
const ignoreAddresses = [
  '0xb91124ecef333f17354add2a8b944c76979fe3ec', // StableVault
  '0x53b37b9a6631c462d74d65d61e1c056ea9daa637'  // Weird PNG-ETH LP Token
];
const zero = '0x0000000000000000000000000000000000000000';
let stopExecution = false;

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

/* ========================================================================================================================================================================= */

// Function to make blockchain queries:
const query = async (address, abi, method, args) => {
  if(!stopExecution) {
    try {
      let ethers_provider = new ethers.providers.JsonRpcProvider(rpcs[0]);
      let contract = new ethers.Contract(address, abi, ethers_provider);
      let result = await contract[method](...args);
      return result;
    } catch {
      try {
        let ethers_provider = new ethers.providers.JsonRpcProvider(rpcs[1]);
        let contract = new ethers.Contract(address, abi, ethers_provider);
        let result = await contract[method](...args);
        return result;
      } catch {
        console.error(`Error calling ${method}(${args}) on ${address}`);
      }
    }
  }
}

/* ========================================================================================================================================================================= */

// Function to fetch all SnowGlobe addresses:
const fetchGlobes = async () => {
  let globes = await query(gaugeProxy, gaugeProxyABI, 'tokens', []);
  return globes;
}

// Function to fetch Gauge address for a SnowGlobe:
const fetchGauge = async (globe) => {
  let strategy = await query(gaugeProxy, gaugeProxyABI, 'getGauge', [globe]);
  return strategy;
}

// Function to fetch Controller address for a SnowGlobe:
const fetchController = async (globe) => {
  let controller = await query(globe, snowGlobeABI, 'controller', []);
  return controller;
}

// Function to fetch underlying token for a SnowGlobe:
const fetchToken = async (globe) => {
  let token = await query(globe, snowGlobeABI, 'token', []);
  return token;
}

// Function to fetch Strategy address for SnowGlobe:
const fetchStrategy = async (controller, token) => {
  let strategy = await query(controller, controllerABI, 'strategies', [token]);
  return strategy;
}

/* ========================================================================================================================================================================= */

// Function to get all pool data:
const getPoolData = async () => {

  // Initializing Pool Data:
  let data = [];

  // Fetching All SnowGlobes:
  let globes = await fetchGlobes();

  // Fetching SnowGlobe Data:
  let promises = globes.map(globe => (async () => {
    if(!ignoreAddresses.includes(globe.toLowerCase())) {
      let gauge = await fetchGauge(globe);
      let controller = await fetchController(globe);
      let token = await fetchToken(globe);
      let strategy = await fetchStrategy(controller, token);
      data.push({globe, controller, token, strategy, gauge});
    }
  })());
  await Promise.all(promises);

  // Communicating Script Outcome:
  stopExecution ? console.warn(`\nExecution was stopped due to errors. Try again or check script.`) : console.info(`\nData for ${data.length} pools was fetched.`);

  // Writing JSON:
  fs.writeFile('./scripts/allPools.json', JSON.stringify(data, null, ' '), 'utf8', (err) => {
    if(err) {
      console.error(err);
    } else {
      console.info(`Successfully updated JSON file.`);
    }
  });
}


/* ========================================================================================================================================================================= */

// Fetching pools:
getPoolData();