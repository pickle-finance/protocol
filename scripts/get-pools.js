
/*
  This script fetches all pool data for all pools in the GaugeProxyV2 contract, and updates the `poolsData.json` file.

  This includes:
  - SnowGlobe Address
  - Strategy Address
  - Gauge Address
  - Controller Address
  - Underlying Token Addresses
  - Underlying Token Symbols
  - Platform Name

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
const lpSymbols = ['PGL', 'JLP'];
const lpAxialSymbols = ['AS4D', 'AC4D', 'AM3D', 'AA3D'];
const zero = '0x0000000000000000000000000000000000000000';
const batchSize = 10; // Use 5-10 for spotty internet connections. 50-100 can be used for good connections.
let progress = 0;
let maxProgress = 0;

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
      console.error(`\n  > Error calling ${method}(${args}) on ${address}`);
      console.warn(`  > Execution was stopped due to errors. Try again or check script.`);
      process.exit(1);
    }
  }
}

/* ========================================================================================================================================================================= */

// Function to fetch all SnowGlobe addresses:
const fetchGlobes = async () => {
  let globes = await query(gaugeProxy, gaugeProxyABI, 'tokens', []);
  return globes;
}

// Function to fetch gauge address for a SnowGlobe:
const fetchGauge = async (globe) => {
  let strategy = await query(gaugeProxy, gaugeProxyABI, 'getGauge', [globe]);
  return strategy;
}

// Function to fetch controller address for a SnowGlobe:
const fetchController = async (globe) => {
  let controller = await query(globe, snowGlobeABI, 'controller', []);
  return controller;
}

// Function to fetch token address and symbol for a SnowGlobe:
const fetchToken = async (globe) => {
  let address = await query(globe, snowGlobeABI, 'token', []);
  let symbol = await query(address, tokenABI, 'symbol', []);
  return {symbol, address};
}

// Function to fetch strategy address for a SnowGlobe:
const fetchStrategy = async (controller, address) => {
  let strategy = await query(controller, controllerABI, 'strategies', [address]);
  return strategy;
}

// Function to fetch underlying token symbols and addresses for a SnowGlobe:
const fetchUnderlyingTokens = async (address) => {
  let token0 = await query(address, lpTokenABI, 'token0', []);
  let token1 = await query(address, lpTokenABI, 'token1', []);
  let symbol0 = await query(token0, tokenABI, 'symbol', []);
  let symbol1 = await query(token1, tokenABI, 'symbol', []);
  return {token0: {symbol: symbol0, address: token0}, token1: {symbol: symbol1, address: token1}};
}

/* ========================================================================================================================================================================= */

// Function to fetch pool platform:
const fetchPlatform = async (token, strategy, globe) => {
  let platform = null;
  if(token.symbol === 'PGL') {
    platform = 'Pangolin';
  } else if(token.symbol === 'JLP' || globe.toLowerCase() === '0x6a52e6b23700a63ea4a0db313ebd386fb510ee3c') {
    platform = 'Trader Joe';
  } else if(lpAxialSymbols.includes(token.symbol)) {
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

/* ========================================================================================================================================================================= */

// Function to get all pool data:
const getPoolData = async () => {

  // Initializations:
  let data = [];
  let startBatch = 0;
  let endBatch = batchSize;

  // Fetching All SnowGlobes:
  console.info(`\n  > Starting script calls...`);
  let globes = await fetchGlobes();
  maxProgress = globes.length;

  // Fetching SnowGlobe Data:
  while(progress < maxProgress) {
    let promises = globes.slice(startBatch, endBatch).map(globe => (async () => {
      if(!ignoreAddresses.includes(globe.toLowerCase())) {
        let gauge = await fetchGauge(globe);
        if(gauge != zero) {
          let controller = await fetchController(globe);
          let token = await fetchToken(globe);
          let strategy = await fetchStrategy(controller, token.address);
          let platform = await fetchPlatform(token, strategy, globe);
          if(lpSymbols.includes(token.symbol)) {
            let underlyingTokens = await fetchUnderlyingTokens(token.address);
            data.push({platform, globe, strategy, gauge, controller, token, underlyingTokens});
          } else {
            data.push({platform, globe, strategy, gauge, controller, token});
          }
        }
      }
      updateProgress();
    })());
    await Promise.all(promises);
    startBatch += batchSize;
    endBatch += batchSize;
  }

  // Writing JSON:
  fs.writeFile('./scripts/poolsData.json', JSON.stringify(data, null, ' '), 'utf8', (err) => {
    if(err) {
      console.error(err);
    } else {
      console.info(`  > Successfully updated JSON file.`);
    }
  });
}


/* ========================================================================================================================================================================= */

// Fetching pools:
getPoolData();