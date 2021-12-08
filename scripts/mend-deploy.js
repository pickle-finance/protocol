const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const pools = [
    // {  
    //   name: "JoeDai",
    //   // harvest: true,
    //   earn: true,
    //   deleverage: true,
    //   keeper: true,
    // },
    // {  
    //   name: "JoeEth", //fail to redeem
    //   // harvest: true,
    //   earn: true,
    //   deleverage: true,
    //   keeper: true,
    //   // strategy_addr: "0x7c57937dD753B47fcb17c3DC49E05888e07425FE",
    //   // approveStrategy: true,
    //   leverage: true
    // },
    // {  
    //   name: "JoeLink",  //fail to redeem
    //   // harvest: true,
    //   earn: true,
    //   deleverage: true,
    //   keeper: true,
    //   leverage: true,
    // },
    // {  
    //   name: "JoeUsdc", //fail to redeem
    //   // harvest: true,
    //   earn: true,
    //   deleverage: true,
    //   keeper: true,
    //   leverage: true,
    // },
    // {  
    //   name: "JoeUsdt", // fail to redeem
    //   // harvest: true,
    //   earn: true,
    //   deleverage: true,
    //   keeper: true,
    //   leverage: true,
    // },
    // {  
    //   name: "JoeWbtc", // fail to redeem
    //   // harvest: true,
    //   earn: true,
    //   deleverage: true,
    //   keeper: true,
    //   leverage: true,
    // },
    {  
      name: "JoeXJoe",
      // harvest: true,
      strategy_addr: "0x4078b1F0192d9b8b14299F8047CE6526F63BfbCa",
      // earn: true,
      // deleverage: true,
      keeper: true,
      setStrategy: true,
      approveStrategy: true,
      // leverage: true,
    },
  ];

  // const controller_addr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85"; //Base
  // const controller_addr = "0xACc69DEeF119AB5bBf14e6Aaf0536eAFB3D6e046"; //Backup
  // const controller_addr = "0xF2FA11Fc9247C23b3B622C41992d8555f6D01D8f"; // bankerJoe
  const controller_addr = "0xFb7102506B4815a24e3cE3eAA6B834BE7a5f2807"; // Old bankerJoe
  // const controller_addr = "0x425A863762BBf24A986d8EaE2A367cb514591C6F"; //Aave
  // const controller_addr = "0xc7D536a04ECC43269B6B95aC1ce0a06E0000D095"; //Axial

  const [deployer] = await ethers.getSigners();
  console.log("Mending deployment with the account:", deployer.address);

  const controller_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[{"type":"address","name":"_governance","internalType":"address"},{"type":"address","name":"_strategist_addr","internalType":"address"},{"type":"address","name":"_timelock","internalType":"address"},{"type":"address","name":"_devfund","internalType":"address"},{"type":"address","name":"_treasury","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"approveGlobeConverter","inputs":[{"type":"address","name":"_converter","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"approveStrategy","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_strategy","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approvedGlobeConverters","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approvedStrategies","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"burn","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"convenienceFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"convenienceFeeMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"converters","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"devfund","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"earn","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"expected","internalType":"uint256"}],"name":"getExpectedReturn","inputs":[{"type":"address","name":"_strategy","internalType":"address"},{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"parts","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"globes","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"inCaseStrategyTokenGetStuck","inputs":[{"type":"address","name":"_strategy","internalType":"address"},{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"inCaseTokensGetStuck","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"max","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"onesplit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"revokeGlobeConverter","inputs":[{"type":"address","name":"_converter","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"revokeStrategy","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_strategy","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setConvenienceFee","inputs":[{"type":"uint256","name":"_convenienceFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setDevFund","inputs":[{"type":"address","name":"_devfund","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGlobe","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_globe","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setOneSplit","inputs":[{"type":"address","name":"_onesplit","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setSplit","inputs":[{"type":"uint256","name":"_split","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setStrategist_addr","inputs":[{"type":"address","name":"_strategist_addr","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setStrategy","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_strategy","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTimelock","inputs":[{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTreasury","inputs":[{"type":"address","name":"_treasury","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"split","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"strategies","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"strategist_addr","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"swapExactGlobeForGlobe","inputs":[{"type":"address","name":"_fromGlobe","internalType":"address"},{"type":"address","name":"_toGlobe","internalType":"address"},{"type":"uint256","name":"_fromGlobeAmount","internalType":"uint256"},{"type":"uint256","name":"_toGlobeMinAmount","internalType":"uint256"},{"type":"address[]","name":"_targets","internalType":"address payable[]"},{"type":"bytes[]","name":"_data","internalType":"bytes[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"timelock_addr","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"treasury","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdraw","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdrawAll","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"yearn","inputs":[{"type":"address","name":"_strategy","internalType":"address"},{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"parts","internalType":"uint256"}]}];
  const gaugeproxy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  const multisig_ABI = [{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address","name":""}],"name":"owners","inputs":[{"type":"uint256","name":""}],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"removeOwner","inputs":[{"type":"address","name":"owner"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"revokeConfirmation","inputs":[{"type":"uint256","name":"transactionId"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"bool","name":""}],"name":"isOwner","inputs":[{"type":"address","name":""}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"bool","name":""}],"name":"confirmations","inputs":[{"type":"uint256","name":""},{"type":"address","name":""}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"count"}],"name":"getTransactionCount","inputs":[{"type":"bool","name":"pending"},{"type":"bool","name":"executed"}],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"addOwner","inputs":[{"type":"address","name":"owner"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"bool","name":""}],"name":"isConfirmed","inputs":[{"type":"uint256","name":"transactionId"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"count"}],"name":"getConfirmationCount","inputs":[{"type":"uint256","name":"transactionId"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address","name":"destination"},{"type":"uint256","name":"value"},{"type":"bytes","name":"data"},{"type":"bool","name":"executed"}],"name":"transactions","inputs":[{"type":"uint256","name":""}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address[]","name":""}],"name":"getOwners","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256[]","name":"_transactionIds"}],"name":"getTransactionIds","inputs":[{"type":"uint256","name":"from"},{"type":"uint256","name":"to"},{"type":"bool","name":"pending"},{"type":"bool","name":"executed"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address[]","name":"_confirmations"}],"name":"getConfirmations","inputs":[{"type":"uint256","name":"transactionId"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"transactionCount","inputs":[],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"changeRequirement","inputs":[{"type":"uint256","name":"_required"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"confirmTransaction","inputs":[{"type":"uint256","name":"transactionId"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[{"type":"uint256","name":"transactionId"}],"name":"submitTransaction","inputs":[{"type":"address","name":"destination"},{"type":"uint256","name":"value"},{"type":"bytes","name":"data"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"MAX_OWNER_COUNT","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"required","inputs":[],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"replaceOwner","inputs":[{"type":"address","name":"owner"},{"type":"address","name":"newOwner"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"executeTransaction","inputs":[{"type":"uint256","name":"transactionId"}],"constant":false},{"type":"constructor","stateMutability":"nonpayable","payable":false,"inputs":[{"type":"address[]","name":"_owners"},{"type":"uint256","name":"_required"}]},{"type":"fallback","stateMutability":"payable","payable":true},{"type":"event","name":"Confirmation","inputs":[{"type":"address","name":"sender","indexed":true},{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Revocation","inputs":[{"type":"address","name":"sender","indexed":true},{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Submission","inputs":[{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Execution","inputs":[{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"ExecutionFailure","inputs":[{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Deposit","inputs":[{"type":"address","name":"sender","indexed":true},{"type":"uint256","name":"value","indexed":false}],"anonymous":false},{"type":"event","name":"OwnerAddition","inputs":[{"type":"address","name":"owner","indexed":true}],"anonymous":false},{"type":"event","name":"OwnerRemoval","inputs":[{"type":"address","name":"owner","indexed":true}],"anonymous":false},{"type":"event","name":"RequirementChange","inputs":[{"type":"uint256","name":"required","indexed":false}],"anonymous":false}];
  const snowglobe_ABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }, { "type": "address", "name": "_timelock", "internalType": "address" }, { "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "available", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "controller", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "_amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "earn", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRatio", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "harvest", "inputs": [{ "type": "address", "name": "reserve", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "max", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "min", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setController", "inputs": [{ "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setMin", "inputs": [{ "type": "uint256", "name": "_min", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setTimelock", "inputs": [{ "type": "address", "name": "_timelock", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "timelock", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "token", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "_shares", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }];
  const strategy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[{"type":"address","name":"_governance","internalType":"address"},{"type":"address","name":"_strategist","internalType":"address"},{"type":"address","name":"_controller","internalType":"address"},{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addKeeper","inputs":[{"type":"address","name":"_keeper","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOfPool","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOfWant","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"benqi","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"comptroller","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"controller","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deleverageToMin","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deleverageUntil","inputs":[{"type":"uint256","name":"_supplyAmount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"payable","outputs":[{"type":"bytes","name":"response","internalType":"bytes"}],"name":"execute","inputs":[{"type":"address","name":"_target","internalType":"address"},{"type":"bytes","name":"_data","internalType":"bytes"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getBorrowable","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getBorrowed","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getBorrowedView","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getColFactor","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getCurrentLeverage","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"},{"type":"uint256","name":"","internalType":"uint256"}],"name":"getHarvestable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getLeveragedSupplyTarget","inputs":[{"type":"uint256","name":"supplyBalance","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getMarketColFactor","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getMaxLeverage","inputs":[]},{"type":"function","stateMutability":"pure","outputs":[{"type":"string","name":"","internalType":"string"}],"name":"getName","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getRedeemable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getSafeLeverageColFactor","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getSafeSyncColFactor","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getSupplied","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getSuppliedUnleveraged","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getSuppliedView","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"harvest","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"harvesters","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"leverageToMax","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"leverageUntil","inputs":[{"type":"uint256","name":"_supplyAmount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pangolinRouter","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceDevFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceDevMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceTreasuryFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceTreasuryMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"png","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"qi","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"qiqi","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"removeKeeper","inputs":[{"type":"address","name":"_keeper","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"revokeHarvester","inputs":[{"type":"address","name":"_harvester","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setColFactorLeverageBuffer","inputs":[{"type":"uint256","name":"_colFactorLeverageBuffer","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setColFactorSyncBuffer","inputs":[{"type":"uint256","name":"_colFactorSyncBuffer","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setController","inputs":[{"type":"address","name":"_controller","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPerformanceDevFee","inputs":[{"type":"uint256","name":"_performanceDevFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPerformanceTreasuryFee","inputs":[{"type":"uint256","name":"_performanceTreasuryFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setStrategist","inputs":[{"type":"address","name":"_strategist","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTimelock","inputs":[{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setWithdrawalDevFundFee","inputs":[{"type":"uint256","name":"_withdrawalDevFundFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setWithdrawalTreasuryFee","inputs":[{"type":"uint256","name":"_withdrawalTreasuryFee","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"strategist","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"sync","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"timelock","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"want","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"wavax","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"whitelistHarvester","inputs":[{"type":"address","name":"_harvester","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdraw","inputs":[{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"balance","internalType":"uint256"}],"name":"withdraw","inputs":[{"type":"address","name":"_asset","internalType":"contract IERC20"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"balance","internalType":"uint256"}],"name":"withdrawAll","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"balance","internalType":"uint256"}],"name":"withdrawForSwap","inputs":[{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalDevFundFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalDevFundMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalTreasuryFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalTreasuryMax","inputs":[]},{"type":"receive","stateMutability":"payable"}];;
  
  const governance_addr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const timelock_addr = governance_addr;
  const gaugeproxy_addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";
  const strategist_addr = "0xc9a51fB9057380494262fd291aED74317332C0a2";
  
  const Controller = new ethers.Contract(controller_addr, controller_ABI, deployer);

  const deploy = async (pool) => {
    console.log(`mending deploy for ${pool.name}`);
    const strategy_name = `Strategy${pool.name}`;
    const snowglobe_name = `SnowGlobe${pool.name}`;
    let lp, strategy, Strategy, globe, SnowGlobe;
  

    /* Deploy Strategy */
    if (!pool.strategy_addr) {
      strategy = await ethers.getContractFactory(strategy_name);
      Strategy = await strategy.deploy(governance_addr, strategist_addr, controller_addr, timelock_addr);
      console.log(`deployed ${strategy_name} at : ${Strategy.address}`);

      /* Handle Old strategy */
      lp = await Strategy.want();
      let old_strategy_addr = await Controller.strategies(lp);
      console.log("old_strategy_addr: ",old_strategy_addr);
      if (old_strategy_addr != 0) {
        // pool.harvest = true;
        pool.earn = true;
        pool.deleverage = true;
        // pool.leverage = true;
      }
      else {
        pool.harvest = false;
        pool.earn = false;
        pool.deleverage = false;
        pool.leverage = false;
      }
    }
    else {
      /* Connect to Strategy */
      Strategy = new ethers.Contract(pool.strategy_addr, strategy_ABI, deployer);
      console.log(`connected to ${strategy_name} at : ${Strategy.address}`);
    }
    
    /* Deploy Snowglobe */
    if (!pool.snowglobe_addr) {
      lp = await Strategy.want();
      let snowglobe_addr = await Controller.globes(lp);
      console.log("snowglobe_addr: ",snowglobe_addr);
      if (snowglobe_addr != 0) {
        SnowGlobe = new ethers.Contract(snowglobe_addr, snowglobe_ABI, deployer);
        pool.setGlobe=true;
        pool.addGauge=true;
      }
      else {
        globe = await ethers.getContractFactory(snowglobe_name);
        SnowGlobe = await globe.deploy(lp, governance_addr, timelock_addr, controller_addr);
        console.log(`deployed ${snowglobe_name} at : ${SnowGlobe.address}`);
      }
    }
    else {
      /* Connect to Snowglobe */
      lp = await Strategy.want();
      SnowGlobe = new ethers.Contract(pool.snowglobe_addr, snowglobe_ABI, deployer);
      console.log(`connected to ${snowglobe_name} at : ${SnowGlobe.address}`);
      pool.setGlobe=true;
      pool.addGauge=true;
    }
  
    /* Set Globe */
    if(!pool.setGlobe){
      console.log('set globe...');
      const setGlobe = await Controller.setGlobe(lp, SnowGlobe.address);
      const tx_setGlobe = await setGlobe.wait(1);
      if (!tx_setGlobe.status) {
        console.error("Error setting the globe for: ",pool.name);
        return;
      }
      console.log("Set Globe in the Controller for: ",pool.name);
    }

    /* Approve Strategy */
    if(!pool.approveStrategy){
      console.log('approve strategy...');
      const approveStrategy = await Controller.approveStrategy(lp, Strategy.address);
      const tx_approveStrategy = await approveStrategy.wait(1);
      if (!tx_approveStrategy.status) {
        console.error("Error approving the strategy for: ",pool.name);
        return;
      }
      console.log("Approved Strategy in the Controller for: ",pool.name);
    }

    /* 
      Harvest old strategy 
      set to true if you want to run 
    */
    if(pool.harvest) {
      console.log('harvest strategy...');
      const strategies = await Controller.strategies(lp);
      const oldStrategy = new ethers.Contract(strategies, strategy_ABI, deployer);
      const harvest = await oldStrategy.harvest();
      const tx_harvest = await harvest.wait(1);
      if (!tx_harvest.status) {
        console.error("Error harvesting the old strategy for: ",pool.name);
        return;
      }
      console.log("Harvested the old strategy for: ",pool.name);
    }

    /* Deleverage to min */
    if (pool.deleverage) {
      console.log('deleverage strategy...');
      const deleverage = await Strategy.deleverageToMin();
      const tx_deleverage = await deleverage.wait(1);
      if (!tx_deleverage.status) {
        console.error("Error deleveraging the old strategy for: ",pool.name);
        return;
      }
      console.log("Deleveraged the old strategy for: ",pool.name);
    }

    /* Set Strategy */
    if (!pool.setStrategy){
      console.log('set strategy...');
      const setStrategy = await Controller.setStrategy(lp, Strategy.address);
      const tx_setStrategy = await setStrategy.wait(1);
      if (!tx_setStrategy.status) {
        console.error("Error setting the strategy for: ",pool.name);
        return;
      }
      console.log("Set Strategy in the Controller for: ",pool.name);
    }

    /* 
      Earn:
      set to true if you want to run 
    */
    if (pool.earn){
      console.log('earn from snowglobe...');
      const earn = await SnowGlobe.earn();
      const tx_earn = await earn.wait(1);
      if (!tx_earn.status) {
        console.error("Error calling earn in the Snowglobe for: ",pool.name);
        return;
      }
      console.log("Called earn in the Snowglobe for: ",pool.name);
    }

    /* Leverage to the max */
    if (pool.leverage) {
      console.log('leverage strategy...');
      const leverage = await Strategy.leverageToMax();
      const tx_leverage = await leverage.wait(1);
      if (!tx_leverage.status) {
        console.error("Error leverage the old strategy for: ",pool.name);
        return;
      }
      console.log("Leverage the old strategy for: ",pool.name);
    }

    /* Whitelist Harvester */
    if(!pool.whitelist){
      console.log('whitelist harvester...');
      const whitelist = await Strategy.whitelistHarvester("0x096a46142C199C940FfEBf34F0fe2F2d674fDB1F");
      const tx_whitelist = await whitelist.wait(1);
      if (!tx_whitelist.status) {
        console.error("Error whitelisting harvester for: ",pool.name);
        return;
      }
      console.log('whitelisted the harvester for: ',pool.name);
    }

    /* 
      Add Keeper 
      set to true if you want to run 
    */
    if(pool.keeper){
      console.log('add keeper...');
      const keeper = await Strategy.addKeeper("0x096a46142C199C940FfEBf34F0fe2F2d674fDB1F");
      const tx_keeper = await keeper.wait(1);
      if (!tx_keeper.status) {
        console.error("Error adding keeper for: ",pool.name);
        return;
      }
      console.log('added keeper for: ',pool.name);
    }
    
    /* Add Gauge */
    if(!pool.addGauge){
      console.log('add gauge...');
      const GaugeProxy = new ethers.Contract(gaugeproxy_addr, gaugeproxy_ABI, deployer);
      const addGauge = await GaugeProxy.addGauge(SnowGlobe.address);

      const tx_addGauge = await addGauge.wait(1);
      if (!tx_addGauge.status) {
        console.error("Error adding the gauge to multisig transaction list for: ",pool.name);
        return;
      }
      console.log(`addGauge for ${pool.name}`);

      const gauge = await GaugeProxy.getGauge(SnowGlobe.address);
      console.log(`deployed Gauge${pool.name} at: ${gauge}`);
    }

    return;
  };

  for (const pool of pools) {
    await deploy(pool);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });