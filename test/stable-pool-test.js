/** NOTES ABOUT THIS TEST FILE
 * - This is called by the test scripts file `all-stable-pools.js`
 * - It should work with n number of tokens in pool, but has only been tested against 4
 * - It should be extended with any optional functionality that needs to be tested against a new pool
 * - If logic differs between pools, add variable to the input parameter with default off value, so we can choose which path each pool should take
 * 
 * TODO:  - Support deploying new swap pools via this file
 * **/

const chai = require("chai");
const { expect } = require('chai');
const { ethers, network, deployments } = require('hardhat');
const { increaseTime, overwriteTokenAmount, increaseBlock, returnSigner, fastForwardAWeek, findSlot } = require("./utils/helpers");
const { BigNumber } = require("@ethersproject/bignumber");
const { setupSigners, snowballAddr, treasuryAddr, MAX_UINT256 } = require("./utils/static");
const IERC20 = [{ "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "OwnershipTransferred", "inputs": [{ "type": "address", "name": "previousOwner", "internalType": "address", "indexed": true }, { "type": "address", "name": "newOwner", "internalType": "address", "indexed": true }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "burn", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "burnFrom", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "initialize", "inputs": [{ "type": "string", "name": "name", "internalType": "string" }, { "type": "string", "name": "symbol", "internalType": "string" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "mint", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "owner", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "renounceOwnership", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "transferOwnership", "inputs": [{ "type": "address", "name": "newOwner", "internalType": "address" }] }];
const txnAmt = "35000000000000000000000";

const doStablePoolTests = (
  name,
  StableVaultAddr,
  tokenList,
  PoolTokenABI = [{ "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "OwnershipTransferred", "inputs": [{ "type": "address", "name": "previousOwner", "internalType": "address", "indexed": true }, { "type": "address", "name": "newOwner", "internalType": "address", "indexed": true }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "burn", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "burnFrom", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "initialize", "inputs": [{ "type": "string", "name": "name", "internalType": "string" }, { "type": "string", "name": "symbol", "internalType": "string" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "mint", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "owner", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "renounceOwnership", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "transferOwnership", "inputs": [{ "type": "address", "name": "newOwner", "internalType": "address" }] }],
  PoolABI = [{ "type": "event", "name": "AddLiquidity", "inputs": [{ "type": "address", "name": "provider", "internalType": "address", "indexed": true }, { "type": "uint256[]", "name": "tokenAmounts", "internalType": "uint256[]", "indexed": false }, { "type": "uint256[]", "name": "fees", "internalType": "uint256[]", "indexed": false }, { "type": "uint256", "name": "invariant", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "lpTokenSupply", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "FlashLoan", "inputs": [{ "type": "address", "name": "receiver", "internalType": "address", "indexed": true }, { "type": "uint8", "name": "tokenIndex", "internalType": "uint8", "indexed": false }, { "type": "uint256", "name": "amount", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "amountFee", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "protocolFee", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "NewAdminFee", "inputs": [{ "type": "uint256", "name": "newAdminFee", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "NewSwapFee", "inputs": [{ "type": "uint256", "name": "newSwapFee", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "NewWithdrawFee", "inputs": [{ "type": "uint256", "name": "newWithdrawFee", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "OwnershipTransferred", "inputs": [{ "type": "address", "name": "previousOwner", "internalType": "address", "indexed": true }, { "type": "address", "name": "newOwner", "internalType": "address", "indexed": true }], "anonymous": false }, { "type": "event", "name": "Paused", "inputs": [{ "type": "address", "name": "account", "internalType": "address", "indexed": false }], "anonymous": false }, { "type": "event", "name": "RampA", "inputs": [{ "type": "uint256", "name": "oldA", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "newA", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "initialTime", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "futureTime", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "RemoveLiquidity", "inputs": [{ "type": "address", "name": "provider", "internalType": "address", "indexed": true }, { "type": "uint256[]", "name": "tokenAmounts", "internalType": "uint256[]", "indexed": false }, { "type": "uint256", "name": "lpTokenSupply", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "RemoveLiquidityImbalance", "inputs": [{ "type": "address", "name": "provider", "internalType": "address", "indexed": true }, { "type": "uint256[]", "name": "tokenAmounts", "internalType": "uint256[]", "indexed": false }, { "type": "uint256[]", "name": "fees", "internalType": "uint256[]", "indexed": false }, { "type": "uint256", "name": "invariant", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "lpTokenSupply", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "RemoveLiquidityOne", "inputs": [{ "type": "address", "name": "provider", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "lpTokenAmount", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "lpTokenSupply", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "boughtId", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "tokensBought", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "StopRampA", "inputs": [{ "type": "uint256", "name": "currentA", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "time", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "TokenSwap", "inputs": [{ "type": "address", "name": "buyer", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "tokensSold", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "tokensBought", "internalType": "uint256", "indexed": false }, { "type": "uint128", "name": "soldId", "internalType": "uint128", "indexed": false }, { "type": "uint128", "name": "boughtId", "internalType": "uint128", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Unpaused", "inputs": [{ "type": "address", "name": "account", "internalType": "address", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "MAX_BPS", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "addLiquidity", "inputs": [{ "type": "uint256[]", "name": "amounts", "internalType": "uint256[]" }, { "type": "uint256", "name": "minToMint", "internalType": "uint256" }, { "type": "uint256", "name": "deadline", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256[]", "name": "", "internalType": "uint256[]" }], "name": "calculateRemoveLiquidity", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "availableTokenAmount", "internalType": "uint256" }], "name": "calculateRemoveLiquidityOneToken", "inputs": [{ "type": "uint256", "name": "tokenAmount", "internalType": "uint256" }, { "type": "uint8", "name": "tokenIndex", "internalType": "uint8" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "calculateSwap", "inputs": [{ "type": "uint8", "name": "tokenIndexFrom", "internalType": "uint8" }, { "type": "uint8", "name": "tokenIndexTo", "internalType": "uint8" }, { "type": "uint256", "name": "dx", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "calculateTokenAmount", "inputs": [{ "type": "uint256[]", "name": "amounts", "internalType": "uint256[]" }, { "type": "bool", "name": "deposit", "internalType": "bool" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "flashLoan", "inputs": [{ "type": "address", "name": "receiver", "internalType": "address" }, { "type": "address", "name": "token", "internalType": "contract IERC20" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }, { "type": "bytes", "name": "params", "internalType": "bytes" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "flashLoanFeeBPS", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getA", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getAPrecise", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getAdminBalance", "inputs": [{ "type": "uint256", "name": "index", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "getToken", "inputs": [{ "type": "uint8", "name": "index", "internalType": "uint8" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getTokenBalance", "inputs": [{ "type": "uint8", "name": "index", "internalType": "uint8" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "getTokenIndex", "inputs": [{ "type": "address", "name": "tokenAddress", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getVirtualPrice", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "initialize", "inputs": [{ "type": "address[]", "name": "_pooledTokens", "internalType": "contract IERC20[]" }, { "type": "uint8[]", "name": "decimals", "internalType": "uint8[]" }, { "type": "string", "name": "lpTokenName", "internalType": "string" }, { "type": "string", "name": "lpTokenSymbol", "internalType": "string" }, { "type": "uint256", "name": "_a", "internalType": "uint256" }, { "type": "uint256", "name": "_fee", "internalType": "uint256" }, { "type": "uint256", "name": "_adminFee", "internalType": "uint256" }, { "type": "address", "name": "lpTokenTargetAddress", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "owner", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "pause", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "paused", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "protocolFeeShareBPS", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "rampA", "inputs": [{ "type": "uint256", "name": "futureA", "internalType": "uint256" }, { "type": "uint256", "name": "futureTime", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "uint256[]", "name": "", "internalType": "uint256[]" }], "name": "removeLiquidity", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }, { "type": "uint256[]", "name": "minAmounts", "internalType": "uint256[]" }, { "type": "uint256", "name": "deadline", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "removeLiquidityImbalance", "inputs": [{ "type": "uint256[]", "name": "amounts", "internalType": "uint256[]" }, { "type": "uint256", "name": "maxBurnAmount", "internalType": "uint256" }, { "type": "uint256", "name": "deadline", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "removeLiquidityOneToken", "inputs": [{ "type": "uint256", "name": "tokenAmount", "internalType": "uint256" }, { "type": "uint8", "name": "tokenIndex", "internalType": "uint8" }, { "type": "uint256", "name": "minAmount", "internalType": "uint256" }, { "type": "uint256", "name": "deadline", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "renounceOwnership", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setAdminFee", "inputs": [{ "type": "uint256", "name": "newAdminFee", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setFlashLoanFees", "inputs": [{ "type": "uint256", "name": "newFlashLoanFeeBPS", "internalType": "uint256" }, { "type": "uint256", "name": "newProtocolFeeShareBPS", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setSwapFee", "inputs": [{ "type": "uint256", "name": "newSwapFee", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "stopRampA", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "swap", "inputs": [{ "type": "uint8", "name": "tokenIndexFrom", "internalType": "uint8" }, { "type": "uint8", "name": "tokenIndexTo", "internalType": "uint8" }, { "type": "uint256", "name": "dx", "internalType": "uint256" }, { "type": "uint256", "name": "minDy", "internalType": "uint256" }, { "type": "uint256", "name": "deadline", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "initialA", "internalType": "uint256" }, { "type": "uint256", "name": "futureA", "internalType": "uint256" }, { "type": "uint256", "name": "initialATime", "internalType": "uint256" }, { "type": "uint256", "name": "futureATime", "internalType": "uint256" }, { "type": "uint256", "name": "swapFee", "internalType": "uint256" }, { "type": "uint256", "name": "adminFee", "internalType": "uint256" }, { "type": "address", "name": "lpToken", "internalType": "contract LPToken" }], "name": "swapStorage", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "transferOwnership", "inputs": [{ "type": "address", "name": "newOwner", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "unpause", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAdminFees", "inputs": [] }]
) => {

  describe(`${name} StablePool Integration Tests`, () => {
    let snapshotId
    let walletSigner, deployer;
    let StablePool, StablePoolToken
    let StableVaultTokenAddr
    let pooledTokens, decimals, lpTokenName, lpTokenSymbol, aValue, fee, adminFee, lpTokenTargetAddress;
    let newPool = true;
    let tokenContracts = [];
    const walletAddr = process.env.WALLET_ADDR;

    //These reset the state after each test is executed 
    beforeEach(async () => {
      snapshotId = await ethers.provider.send('evm_snapshot');
    })

    afterEach(async () => {
      await ethers.provider.send('evm_revert', [snapshotId]);
    })

    before(async () => {
      walletSigner = await returnSigner(walletAddr);

      /**=======Get Token Contracts=======**/
      // -- When adding new sets of token pools, be sure to use slot20 to verify the slot the ERC20 employs
      // -- If slot is 0 then no changes required, if not be sure to add to the case/switch statement for helpers::findSlot()
      for (let item of tokenList) {
        process.stdout.write(`\tDeploying token contract: ${item}}`);
        let contract = await ethers.getContractAt(IERC20, item, walletSigner);
        process.stdout.write("..");
        tokenContracts.push(contract);
        process.stdout.write(`${await contract.symbol()} loaded\n`);
        let slot = findSlot(item);
        await overwriteTokenAmount(item, walletAddr, txnAmt, slot);

      }

      if (StableVaultAddr == "") {
        //TODO: Make this part of the IF statement work
        // Use this for testing new stablevaults
        const stablePoolFactory = await ethers.getContractFactory("SwapFlashLoan");
        StablePool = await stablePoolFactory.deploy();
        StableVaultAddr = StablePool.address;

        // Arrange init data
        pooledTokens = [testAToken.address, testBToken.address, testCToken.address, testDToken.address];
        decimals = [18, 18, 18, 6];
        lpTokenName = "Timbo Test Pool";
        lpTokenSymbol = "TIMPOOL";
        aValue = 60;
        fee = 3000000;
        adminFee = 1000000;
        lpTokenTargetAddress = "0x834ac088077db3fba31fde3829c77a46d038efc9";

        // Perform Init
        await StablePool.initialize(
          pooledTokens,
          decimals,
          lpTokenName,
          lpTokenSymbol,
          aValue,
          fee,
          adminFee,
          lpTokenTargetAddress,
        );

      } else {
        // Load local instance of Stablevault contract from existing contract deployed on chain
        newPool = false;
        StablePool = await ethers.getContractAt(PoolABI, StableVaultAddr, deployer);
        let owner = await StablePool.owner();
        deployer = await returnSigner(owner);
        console.log(`\tDeployer Address is ${deployer._address}`)

        const response = await StablePool.swapStorage();
        StableVaultTokenAddr = response[6];
        console.log(`\tLP Token Address is : ${StableVaultTokenAddr}`);
        StablePoolToken = await ethers.getContractAt(PoolTokenABI, StableVaultTokenAddr, deployer);

      }
      console.log(`\tStablePool Address is : ${StablePool.address}`);

      let slot = findSlot(StableVaultTokenAddr);
      await overwriteTokenAmount(StableVaultTokenAddr, walletAddr, txnAmt, slot);
      await approveAll(tokenContracts, StableVaultAddr);
    });

    describe("Default Values", async () => {
      it("Pool is initialized correctly", async () => {
        //check owner
        const owner = await StablePool.owner();
        expect(owner, "Owner doesn't match deployer").to.contains(deployer._address);

        //check paused = false
        const paused = await StablePool.paused();
        expect(paused, "Pool is paused").to.be.false;

        if (newPool) {
          //check A
          const A = await StablePool.getA();
          expect(parseInt(A), "A value doesn't match").to.equals(aValue);

          // TODO: Check that each added token is present in pool
          //forEach token in pool expect to be in token array

        }

      })
    })

    describe("When adding liquidity", async () => {
      it("the pool balance increases", async () => {
        const firstAsset = tokenContracts[0];
        const txnAmt = "2500";
        const amt = ethers.utils.parseEther(txnAmt);
        const preTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

        let amounts = Array(tokenList.length).fill(0);
        amounts[0] = amt;

        await firstAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        await StablePool.connect(walletSigner).addLiquidity(amounts, 0, 999999999999999);

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);
        const postTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));

        expect(Number(preTokenAmt), "Pool balance not deducted correctly").to.be.lessThan(Number(postTokenAmt));
        expect(Number(balsBefore[0])).to.be.greaterThan(Number(balsAfter[0]));
      })

      it("reverts when the pool is paused", async () => {
        await StablePool.connect(deployer).pause();
        const paused = await StablePool.paused();
        expect(paused, "Pool isn't being paused").to.be.true;

        let amounts = Array(tokenList.length).fill(0);
        amounts[0] = ethers.utils.parseEther("500");
        await expect(StablePool.connect(walletSigner).addLiquidity(amounts, 0, 999999999999999)).to.be.reverted;
      })

      it("multiple tokens can be added at same time", async () => {
        const firstAsset = tokenContracts[1];
        const secondAsset = tokenContracts[2];
        const txnAmt = "3700";
        const amt = ethers.utils.parseEther(txnAmt);
        const preTokenAmtA = ethers.utils.formatEther(await StablePool.getTokenBalance(1));
        const preTokenAmtB = ethers.utils.formatEther(await StablePool.getTokenBalance(2));
        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

        let amounts = Array(tokenList.length).fill(0);
        amounts[1] = amt;
        amounts[2] = amt;

        await firstAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        await secondAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        await StablePool.connect(walletSigner).addLiquidity(amounts, 0, MAX_UINT256);

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);
        const postTokenAmtA = ethers.utils.formatEther(await StablePool.getTokenBalance(1));
        const postTokenAmtB = ethers.utils.formatEther(await StablePool.getTokenBalance(2));

        expect(Number(balsBefore[1])).to.be.greaterThan(Number(balsAfter[1]));
        expect(Number(balsBefore[2])).to.be.greaterThan(Number(balsAfter[2]));
        expect(Number(postTokenAmtA), "TokenA amount not increased in pool").to.be.greaterThan(Number(preTokenAmtA));
        expect(Number(postTokenAmtB), "TokenB amount not increased in pool").to.be.greaterThan(Number(preTokenAmtB));
      })


      it("the liquidity can be removed equally", async () => {
        let amounts = Array(tokenList.length).fill(0);
        let liquidity = "12000";
        let txn = ethers.utils.parseEther(liquidity);
        let balsBefore = await getAllBalances(walletAddr, tokenContracts);

        await StablePoolToken.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        await StablePool.connect(walletSigner).removeLiquidity(txn, amounts, MAX_UINT256);

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);

        // Check that each token balance has been increased for user when withdrawing liquidity
        let diffs = Array();
        for (let i in balsAfter) {
          expect(Number(balsAfter[i]), `Balance of item ${i} is not increased`).to.be.greaterThan(Number(balsBefore[i]));
          diffs.push(Number(balsAfter[i]) - Number(balsBefore[i]));
        }

        // Check that the total amount withdrawn is roughly that of the withdrawal amount
        let total = 0;
        for (let item of diffs) {
          total += Number(item);
          //console.log(`item is ${item}`);
        }
        //console.log(`total is ${total}`);
        console.log(`\tLiquidity withdrawn is ${liquidity} compared to balance increased by ${total}`);
        let ratio = Number(total) / Number(liquidity);
        // TODO: Investigate why there's so much slippage, as in why we get hardly any TUSD back
        expect(ratio, "User receives less balance than liquidity withdrawn").to.be.greaterThan(0.80);
      })

      it("the liquidity can be removed one-sided", async () => {
        let amounts = Array(tokenList.length).fill(0);
        let liquidity = "1200";
        let index = 1;
        let txn = ethers.utils.parseEther(liquidity);
        let balsBefore = await getAllBalances(walletAddr, tokenContracts);

        await StablePoolToken.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        await StablePool.connect(walletSigner).removeLiquidityOneToken(txn, index, amounts, MAX_UINT256);

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);

        expect(Number(balsAfter[index])).to.be.greaterThan(Number(balsBefore[index]))
        expect(Number(balsBefore[index + 1])).to.be.equals(Number(balsBefore[index + 1]))
      })

    })

    describe("When swapping tokens", async () => {
      it("can swap tokenA for tokenB", async () => {
        const txnAmt = "25000";
        let amt = ethers.utils.parseEther(txnAmt);
        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

        await approveAll(tokenContracts, StableVaultAddr);
        await StablePool.connect(walletSigner).swap(0, 1, amt, 0, 999999999999999);

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);

        expect(Number(balsBefore[0])).to.be.greaterThan(Number(balsAfter[0]));
        expect(Number(balsBefore[1])).to.be.lessThan(Number(balsAfter[1]));
        expect(Number(balsBefore[2])).to.be.equals(Number(balsAfter[2]));
        expect(Number(balsBefore[3])).to.be.equals(Number(balsAfter[3]));
      })

      if (tokenList.length > 2) {
        it("can swap tokenB for tokenC", async () => {
          const txnAmt = "25000";
          let amt = ethers.utils.parseEther(txnAmt);
          const balsBefore = await getAllBalances(walletAddr, tokenContracts);

          await approveAll(tokenContracts, StableVaultAddr);
          await StablePool.connect(walletSigner).swap(1, 2, amt, 0, 999999999999999);

          const balsAfter = await getAllBalances(walletAddr, tokenContracts);

          expect(Number(balsBefore[0])).to.be.equals(Number(balsAfter[0]));
          expect(Number(balsBefore[1])).to.be.greaterThan(Number(balsAfter[1]));
          expect(Number(balsBefore[2])).to.be.lessThan(Number(balsAfter[2]));
          expect(Number(balsBefore[3])).to.be.equals(Number(balsAfter[3]));
        })

        if (tokenList.length > 3) {
          it("can swap tokenC for tokenD", async () => {
            const txnAmt = "25000";
            let amt = ethers.utils.parseEther(txnAmt);
            const balsBefore = await getAllBalances(walletAddr, tokenContracts);

            await approveAll(tokenContracts, StableVaultAddr);
            await StablePool.connect(walletSigner).swap(2, 3, amt, 0, 999999999999999);

            const balsAfter = await getAllBalances(walletAddr, tokenContracts);

            expect(Number(balsBefore[0])).to.be.equals(Number(balsAfter[0]));
            expect(Number(balsBefore[1])).to.be.equals(Number(balsAfter[1]));
            expect(Number(balsBefore[2])).to.be.greaterThan(Number(balsAfter[2]));
            expect(Number(balsBefore[3])).to.be.lessThan(Number(balsAfter[3]));
          })

          it("can swap tokenD for tokenA", async () => {
            const txnAmt = "25000";
            let amt = ethers.utils.parseEther(txnAmt);
            const balsBefore = await getAllBalances(walletAddr, tokenContracts);

            await approveAll(tokenContracts, StableVaultAddr);
            await StablePool.connect(walletSigner).swap(3, 0, amt, 0, 999999999999999);

            const balsAfter = await getAllBalances(walletAddr, tokenContracts);

            expect(Number(balsBefore[0])).to.be.lessThan(Number(balsAfter[0]));
            expect(Number(balsBefore[1])).to.be.equals(Number(balsAfter[1]));
            expect(Number(balsBefore[2])).to.be.equals(Number(balsAfter[2]));
            expect(Number(balsBefore[3])).to.be.greaterThan(Number(balsAfter[3]));
          })
        }
      }

    })

    describe("When minimum amounts are requested", async () => {
      it("fails when swap slippage is too high", async () => {
        let amt = "1200";
        let txn = ethers.utils.parseEther(amt);
        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

        await expect(StablePool.connect(walletSigner).swap(0, 1, txn, txn, 999999999999999)).to.be.revertedWith("Swap didn't result in min tokens");

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);

        for (let i in balsBefore) {
          expect(Number(balsBefore[i]), `Balance[${i}] should be unaffected by failed swap`).to.be.equals(Number(balsAfter[i]));
        }

      })

      it("fails when addLiquidity slippage is too high", async () => {
        const firstAsset = tokenContracts[0];

        await firstAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        const txnAmt = "2500";
        const amt = ethers.utils.parseEther(txnAmt);

        const preTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

        let amounts = Array(tokenList.length).fill(0);
        amounts[0] = amt;
        await expect(StablePool.connect(walletSigner).addLiquidity(amounts, amt, 999999999999999)).to.be.reverted;

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);
        const postTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
        let match = verifyBalances(balsBefore, balsAfter);

        expect(match, `User balances should be unaffected by failed addLiquidity`).to.be.true;
        expect(Number(preTokenAmt), "Pool balance should be unaffected by failed addLiquidity").to.be.equals(Number(postTokenAmt));
      })

      it("fails when removeLiquidity slippage is too high", async () => {
        let liquidity = "12000";
        let txn = ethers.utils.parseEther(liquidity);
        let amounts = Array(tokenList.length).fill(txn);

        const preTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

        await StablePoolToken.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
        await expect(StablePool.connect(walletSigner).removeLiquidity(txn, amounts, MAX_UINT256)).to.be.reverted;

        const balsAfter = await getAllBalances(walletAddr, tokenContracts);
        const postTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
        let match = verifyBalances(balsBefore, balsAfter);

        expect(match, `User balances should be unaffected by failed removeLiquidity`).to.be.true;
        expect(Number(preTokenAmt), "Pool balance should be unaffected by failed removeLiquidity").to.be.equals(Number(postTokenAmt));
      })
    })



  })

  async function approveAll(tokenList, address) {
    for (let item of tokenList) {
      await item.approve(address, MAX_UINT256);
    }
  }

  function verifyBalances(pre, post) {
    let bool = true;
    for (let i in pre) {
      if (pre[i] != [post[i]]) {
        bool = false
      }
    };

    return bool
  }

  async function getAllBalances(address, tokenContracts) {
    let balances = Array();
    let string = Array();
    for (let contract of tokenContracts) {
      let bal = ethers.utils.formatEther(await contract.balanceOf(address));
      let num = Number(bal).toFixed(2);
      balances.push(bal);
      string.push(num + " " + await contract.symbol())
    };
    console.log(`\tBalances of user are: ${string}`);

    return balances
  }

}

module.exports = { doStablePoolTests };