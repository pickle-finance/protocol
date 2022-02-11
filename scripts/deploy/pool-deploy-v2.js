const { readFileSync, writeFileSync } = require("fs");
const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const verify = false;
  const poolsJSON = readFileSync("./scripts/deploy.json");//loded from files
  const pools = JSON.parse(poolsJSON);

  const [deployer] = await ethers.getSigners();
  console.log("Deploying/Repairing pools with the account:", deployer.address);

  const controller_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[{"type":"address","name":"_governance","internalType":"address"},{"type":"address","name":"_strategist_addr","internalType":"address"},{"type":"address","name":"_timelock","internalType":"address"},{"type":"address","name":"_devfund","internalType":"address"},{"type":"address","name":"_treasury","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"approveGlobeConverter","inputs":[{"type":"address","name":"_converter","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"approveStrategy","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_strategy","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approvedGlobeConverters","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approvedStrategies","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"burn","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"convenienceFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"convenienceFeeMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"converters","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"devfund","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"earn","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"expected","internalType":"uint256"}],"name":"getExpectedReturn","inputs":[{"type":"address","name":"_strategy","internalType":"address"},{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"parts","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"globes","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"inCaseStrategyTokenGetStuck","inputs":[{"type":"address","name":"_strategy","internalType":"address"},{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"inCaseTokensGetStuck","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"max","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"onesplit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"revokeGlobeConverter","inputs":[{"type":"address","name":"_converter","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"revokeStrategy","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_strategy","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setConvenienceFee","inputs":[{"type":"uint256","name":"_convenienceFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setDevFund","inputs":[{"type":"address","name":"_devfund","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGlobe","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_globe","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setOneSplit","inputs":[{"type":"address","name":"_onesplit","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setSplit","inputs":[{"type":"uint256","name":"_split","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setStrategist_addr","inputs":[{"type":"address","name":"_strategist_addr","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setStrategy","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_strategy","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTimelock","inputs":[{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTreasury","inputs":[{"type":"address","name":"_treasury","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"split","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"strategies","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"strategist_addr","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"swapExactGlobeForGlobe","inputs":[{"type":"address","name":"_fromGlobe","internalType":"address"},{"type":"address","name":"_toGlobe","internalType":"address"},{"type":"uint256","name":"_fromGlobeAmount","internalType":"uint256"},{"type":"uint256","name":"_toGlobeMinAmount","internalType":"uint256"},{"type":"address[]","name":"_targets","internalType":"address payable[]"},{"type":"bytes[]","name":"_data","internalType":"bytes[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"timelock_addr","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"treasury","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdraw","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdrawAll","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"yearn","inputs":[{"type":"address","name":"_strategy","internalType":"address"},{"type":"address","name":"_token","internalType":"address"},{"type":"uint256","name":"parts","internalType":"uint256"}]}];
  const gaugeproxy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  const snowglobe_ABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }, { "type": "address", "name": "_timelock", "internalType": "address" }, { "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "available", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "controller", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "_amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "earn", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRatio", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "harvest", "inputs": [{ "type": "address", "name": "reserve", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "max", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "min", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setController", "inputs": [{ "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setMin", "inputs": [{ "type": "uint256", "name": "_min", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setTimelock", "inputs": [{ "type": "address", "name": "_timelock", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "timelock", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "token", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "_shares", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }];
  const strategy_ABI = [{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addKeeper","inputs":[{"type":"address","name":"_keeper","internalType":"address"}]},{"type":"constructor","stateMutability":"nonpayable","inputs":[{"type":"address","name":"_governance","internalType":"address"},{"type":"address","name":"_strategist","internalType":"address"},{"type":"address","name":"_controller","internalType":"address"},{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOfPool","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOfWant","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"controller","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"payable","outputs":[{"type":"bytes","name":"response","internalType":"bytes"}],"name":"execute","inputs":[{"type":"address","name":"_target","internalType":"address"},{"type":"bytes","name":"_data","internalType":"bytes"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getHarvestable","inputs":[]},{"type":"function","stateMutability":"pure","outputs":[{"type":"string","name":"","internalType":"string"}],"name":"getName","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"harvest","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"harvesters","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"keep","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"keepMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pangolinRouter","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceDevFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceDevMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceTreasuryFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"performanceTreasuryMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"png","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"png_avax_snob_lp","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"png_avax_snob_lp_rewards","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"revokeHarvester","inputs":[{"type":"address","name":"_harvester","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"rewards","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setController","inputs":[{"type":"address","name":"_controller","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setkeep","inputs":[{"type":"uint256","name":"_keep","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPerformanceDevFee","inputs":[{"type":"uint256","name":"_performanceDevFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPerformanceTreasuryFee","inputs":[{"type":"uint256","name":"_performanceTreasuryFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setStrategist","inputs":[{"type":"address","name":"_strategist","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTimelock","inputs":[{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setWithdrawalDevFundFee","inputs":[{"type":"uint256","name":"_withdrawalDevFundFee","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setWithdrawalTreasuryFee","inputs":[{"type":"uint256","name":"_withdrawalTreasuryFee","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"snob","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"strategist","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"timelock","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"token1","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"want","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"wavax","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"whitelistHarvester","inputs":[{"type":"address","name":"_harvester","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdraw","inputs":[{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"balance","internalType":"uint256"}],"name":"withdraw","inputs":[{"type":"address","name":"_asset","internalType":"contract IERC20"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"balance","internalType":"uint256"}],"name":"withdrawAll","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"balance","internalType":"uint256"}],"name":"withdrawForSwap","inputs":[{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalDevFundFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalDevFundMax","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalTreasuryFee","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"withdrawalTreasuryMax","inputs":[]}];
  
  const timelock_addr = "0x3d88b8022142ea2693ba43BA349F89256392d59b";
  const governance_addr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const gaugeproxy_addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";
  const strategist_addr = timelock_addr;

  const deploy = async (name) => {
    console.log(`mending deploy for ${name}`);
    const strategy_name = `Strategy${name}`;
    const snowglobe_name = `SnowGlobe${name}`;
    let lp, strategy, Strategy, globe, SnowGlobe, controller_addr;

    switch(pools[name].controller){
      case "Aave": controller_addr = "0x425A863762BBf24A986d8EaE2A367cb514591C6F"; break;
      case "Axial": controller_addr = "0xc7D536a04ECC43269B6B95aC1ce0a06E0000D095"; break;
      case "Backup": controller_addr = "0xACc69DEeF119AB5bBf14e6Aaf0536eAFB3D6e046"; break;
      case "BankerJoe": controller_addr = "0xFb7102506B4815a24e3cE3eAA6B834BE7a5f2807"; break;
      case "BankerJoe1": controller_addr = "0xF2FA11Fc9247C23b3B622C41992d8555f6D01D8f"; break;
      case "Benqi": controller_addr = "0x252B5fD3B1Cb07A2109bF36D5bDE6a247c6f4B59"; break;    
      case "TraderJoe": controller_addr = "0xCEB829a0881350689dAe8CBD77D0E012cf7a6a3f"; break;
      case "OldBenqi": controller_addr = "0x8Ffa3c1547479B77D9524316D5192777bedA40a1"; break;
      case "Optimizer": controller_addr = "0x2F0b4e7aC032d0708C082994Fb21Dd75DB514744"; break;
      case "Platypus": controller_addr = "0x14559fb4d15Cf8DCbc35b7EDd1215d56c0468202"; break; 
      default: controller_addr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85"; break; //Base
    }

    // if there is no targets or data array, create one
    if (!pools[name].targets) {
      pools[name].targets = [];
    }
    if (!pools[name].data) {
      pools[name].data = [];
    }

    const Controller = new ethers.Contract(controller_addr, controller_ABI, deployer);
    const IController = new ethers.utils.Interface(controller_ABI);
  
    /* Deploy Strategy */
    if (!pools[name].strategy_addr) {
      strategy = await ethers.getContractFactory(strategy_name);
      Strategy = await strategy.deploy(governance_addr, strategist_addr, controller_addr, timelock_addr);
      pools[name].strategy_addr = Strategy.address;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));

      console.log(`deployed ${strategy_name} at : ${Strategy.address}`);
      if (verify) {
        await hre.run("verify:verify", {
          address: Strategy.address,
          constructorArguments: [governance_addr, strategist_addr, controller_addr, timelock_addr],
        });
        pools[name].verifiedStrategy = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
        console.log(`verified ${strategy_name}`);
      }
    }
    else {
      /* Connect to Strategy */
      Strategy = new ethers.Contract(pools[name].strategy_addr, strategy_ABI, deployer);
      console.log(`connected to ${strategy_name} at : ${Strategy.address}`);
      let strategy_controller = await Strategy.controller();
      if(!pools[name].strategy_set_controller && strategy_controller != controller_addr) {
        pools[name].targets.push(Strategy.address);
        const IStrategy = new ethers.utils.Interface(strategy_ABI);
        pools[name].data.push(IStrategy.encodeFunctionData("setController", [controller_addr]));
        pools[name].strategy_set_controller = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
        console.log(`encoded setController in the Strategy for ${name}`);
      }
    }
    
    /* Deploy Snowglobe */
    if (!pools[name].snowglobe_addr) {
      lp = await Strategy.want();
      let snowglobe_addr = await Controller.globes(lp);
      console.log("snowglobe_addr: ",snowglobe_addr);
      // If we didn't supply a globe, but we found an old one...
      if (snowglobe_addr != 0) {
        SnowGlobe = new ethers.Contract(snowglobe_addr, snowglobe_ABI, deployer);
        pools[name].snowglobe_addr = SnowGlobe.address;
        pools[name].setGlobe=true;
        pools[name].addGauge=true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      }
      // If we didn't supply a globe, and we didn't have one previously...
      else {
        globe = await ethers.getContractFactory(snowglobe_name);
        SnowGlobe = await globe.deploy(lp, governance_addr, timelock_addr, controller_addr);
        console.log(`deployed ${snowglobe_name} at : ${SnowGlobe.address}`);
        pools[name].snowglobe_addr = SnowGlobe.address;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
        if (verify) {
          await hre.run("verify:verify", {
            address: SnowGlobe.address,
            constructorArguments: [lp, governance_addr, timelock_addr, controller_addr],
          });
          pools[name].verifiedSnowglobe = true;
          writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
          console.log(`verified ${snowglobe_name}`);
        }
      }
    }
    else {
      lp = await Strategy.want();
      SnowGlobe = new ethers.Contract(pools[name].snowglobe_addr, snowglobe_ABI, deployer);
      console.log(`connected to ${snowglobe_name} at : ${SnowGlobe.address}`);
      let globe_controller = await SnowGlobe.controller();
      if(!pools[name].globe_set_controller && globe_controller != controller_addr) {
        pools[name].targets.push(SnowGlobe.address);
        const ISnowGlobe = new ethers.utils.Interface(snowglobe_ABI);
        pools[name].data.push(ISnowGlobe.encodeFunctionData("setController", [controller_addr]));
        pools[name].globe_set_controller = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
        console.log(`encoded setController in the SnowGlobe for ${name}`);
      }

      let old_snowglobe_addr = await Controller.globes(lp);
      console.log("old snowglobe_addr: ",old_snowglobe_addr);
      // If we supplied a globe and it is an old one...
      if (old_snowglobe_addr == SnowGlobe.address) {
        pools[name].setGlobe=true;
        pools[name].addGauge=true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      }
      else if(old_snowglobe_addr != 0) {
        console.warn(`WARNING: Globe Previously Set: ${old_snowglobe_addr}`);
      }
      
    }

    // We are now building towards a proposal.
  
    /* Encoding for Set Globe */
    if(!pools[name].setGlobe){
      pools[name].targets.push(controller_addr);
      pools[name].data.push(IController.encodeFunctionData("setGlobe", [lp, pools[name].snowglobe_addr]));
      pools[name].setGlobe = true;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      console.log(`encoded setGlobe for ${name}`);
    }

    /* Encoding for Approve Strategy */
    if(!pools[name].approveStrategy){
      pools[name].targets.push(controller_addr);
      pools[name].data.push(IController.encodeFunctionData("approveStrategy", [lp, pools[name].strategy_addr]));
      pools[name].approveStrategy = true;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      console.log(`encoded approveStrategy for ${name}`);
    }



    /* 
      Encoding Harvest for old strategy
      only runs if there was an old strategy on the same controller
      Be sure to check that the Timelock Controller has the correct permissions in the old strategy
    */
    if(!pools[name].harvest) {
      const old_strategy_addr = await Controller.strategies(lp);
      if (old_strategy_addr != 0) {
        const IStrategy = new ethers.utils.Interface(strategy_ABI);
        pools[name].targets.push(old_strategy_addr);
        pools[name].data.push(IStrategy.encodeFunctionData("harvest", []));
        pools[name].harvest = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
        console.log(`encoded harvest for ${name}`);
      }
      else {
        pools[name].harvest = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      }
    }

    /* Encoding for Set Strategy */
    if (!pools[name].setStrategy){
      pools[name].targets.push(controller_addr);
      pools[name].data.push(IController.encodeFunctionData("setStrategy", [lp, pools[name].strategy_addr]));
      pools[name].setStrategy = true;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      console.log(`encoded setStrategy for ${name}`);
    }

    /* Encoding for Earn */
    if (!pools[name].earn){
      const old_strategy_addr = await Controller.strategies(lp);
      if (old_strategy_addr != 0) {
        const ISnowGlobe = new ethers.utils.Interface(snowglobe_ABI);
        pools[name].targets.push(pools[name].snowglobe_addr);
        pools[name].data.push(ISnowGlobe.encodeFunctionData("earn", []));
        pools[name].earn = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
        console.log(`encoded earn for ${name}`);
      }
      else {
        pools[name].earn = true;
        writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      }
    }

    /* Encoding for Whitelist Harvester */
    if(!pools[name].whitelist){
      const IStrategy = new ethers.utils.Interface(strategy_ABI);
      pools[name].targets.push(pools[name].strategy_addr);
      pools[name].data.push(IStrategy.encodeFunctionData("whitelistHarvester", ["0x096a46142C199C940FfEBf34F0fe2F2d674fDB1F"]));
      pools[name].whitelist = true;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      console.log(`encoded whitelistHarvester for ${name}`);
    }

    /* Encoding for Add Keeper */
    if(
      !pools[name].keeper 
      && (pools[name].controller == "Aave"
      || pools[name].controller == "BankerJoe"
      || pools[name].controller == "Benqi"
      || pools[name].controller == "Optimizer")
    ){
      const IStrategy = new ethers.utils.Interface(strategy_ABI);
      pools[name].targets.push(pools[name].strategy_addr);
      pools[name].data.push(IStrategy.encodeFunctionData("addKeeper", ["0x096a46142C199C940FfEBf34F0fe2F2d674fDB1F"]));
      pools[name].keeper = true;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      console.log(`encoded addKeeper for ${name}`);
    }
    
    /* Encoding for Add Gauge */
    if(!pools[name].addGauge){
      const IGaugeProxy = new ethers.utils.Interface(gaugeproxy_ABI);
      pools[name].targets.push(gaugeproxy_addr);
      pools[name].data.push(IGaugeProxy.encodeFunctionData("addGauge", [pools[name].snowglobe_addr]));
      pools[name].addGauge = true;
      writeFileSync("./scripts/deploy.json", JSON.stringify(pools));
      console.log(`encoded addGauge for ${name}`);
    }
    return;
  };

  for (const name in pools) {
    await deploy(name);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });