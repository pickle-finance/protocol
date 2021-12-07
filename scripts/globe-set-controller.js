const { ethers } = require("hardhat");
require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

async function main() {
  const multisig_ABI = [{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address","name":""}],"name":"owners","inputs":[{"type":"uint256","name":""}],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"removeOwner","inputs":[{"type":"address","name":"owner"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"revokeConfirmation","inputs":[{"type":"uint256","name":"transactionId"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"bool","name":""}],"name":"isOwner","inputs":[{"type":"address","name":""}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"bool","name":""}],"name":"confirmations","inputs":[{"type":"uint256","name":""},{"type":"address","name":""}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"calcMaxWithdraw","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"count"}],"name":"getTransactionCount","inputs":[{"type":"bool","name":"pending"},{"type":"bool","name":"executed"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"dailyLimit","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"lastDay","inputs":[],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"addOwner","inputs":[{"type":"address","name":"owner"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"bool","name":""}],"name":"isConfirmed","inputs":[{"type":"uint256","name":"transactionId"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":"count"}],"name":"getConfirmationCount","inputs":[{"type":"uint256","name":"transactionId"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address","name":"destination"},{"type":"uint256","name":"value"},{"type":"bytes","name":"data"},{"type":"bool","name":"executed"}],"name":"transactions","inputs":[{"type":"uint256","name":""}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address[]","name":""}],"name":"getOwners","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256[]","name":"_transactionIds"}],"name":"getTransactionIds","inputs":[{"type":"uint256","name":"from"},{"type":"uint256","name":"to"},{"type":"bool","name":"pending"},{"type":"bool","name":"executed"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"address[]","name":"_confirmations"}],"name":"getConfirmations","inputs":[{"type":"uint256","name":"transactionId"}],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"transactionCount","inputs":[],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"changeRequirement","inputs":[{"type":"uint256","name":"_required"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"confirmTransaction","inputs":[{"type":"uint256","name":"transactionId"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[{"type":"uint256","name":"transactionId"}],"name":"submitTransaction","inputs":[{"type":"address","name":"destination"},{"type":"uint256","name":"value"},{"type":"bytes","name":"data"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"changeDailyLimit","inputs":[{"type":"uint256","name":"_dailyLimit"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"MAX_OWNER_COUNT","inputs":[],"constant":true},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"required","inputs":[],"constant":true},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"replaceOwner","inputs":[{"type":"address","name":"owner"},{"type":"address","name":"newOwner"}],"constant":false},{"type":"function","stateMutability":"nonpayable","payable":false,"outputs":[],"name":"executeTransaction","inputs":[{"type":"uint256","name":"transactionId"}],"constant":false},{"type":"function","stateMutability":"view","payable":false,"outputs":[{"type":"uint256","name":""}],"name":"spentToday","inputs":[],"constant":true},{"type":"constructor","stateMutability":"nonpayable","payable":false,"inputs":[{"type":"address[]","name":"_owners"},{"type":"uint256","name":"_required"},{"type":"uint256","name":"_dailyLimit"}]},{"type":"fallback","stateMutability":"payable","payable":true},{"type":"event","name":"DailyLimitChange","inputs":[{"type":"uint256","name":"dailyLimit","indexed":false}],"anonymous":false},{"type":"event","name":"Confirmation","inputs":[{"type":"address","name":"sender","indexed":true},{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Revocation","inputs":[{"type":"address","name":"sender","indexed":true},{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Submission","inputs":[{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Execution","inputs":[{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"ExecutionFailure","inputs":[{"type":"uint256","name":"transactionId","indexed":true}],"anonymous":false},{"type":"event","name":"Deposit","inputs":[{"type":"address","name":"sender","indexed":true},{"type":"uint256","name":"value","indexed":false}],"anonymous":false},{"type":"event","name":"OwnerAddition","inputs":[{"type":"address","name":"owner","indexed":true}],"anonymous":false},{"type":"event","name":"OwnerRemoval","inputs":[{"type":"address","name":"owner","indexed":true}],"anonymous":false},{"type":"event","name":"RequirementChange","inputs":[{"type":"uint256","name":"required","indexed":false}],"anonymous":false}];
  const snowglobe_ABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }, { "type": "address", "name": "_timelock", "internalType": "address" }, { "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "available", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "controller", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "_amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "earn", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRatio", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "harvest", "inputs": [{ "type": "address", "name": "reserve", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "max", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "min", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setController", "inputs": [{ "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setMin", "inputs": [{ "type": "uint256", "name": "_min", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setTimelock", "inputs": [{ "type": "address", "name": "_timelock", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "timelock", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "token", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "_shares", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }];
  

  const [signer] = await ethers.getSigners();

  //Testing Below

  // SNOB addresses
  const treasury_addr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const council_addr = "0x028933a66DD0cCC239a3d5c2243b2d96672f11F5";

  const pools = [
    {
      name: "JoeLink",
      snowglobe: "0x6C6B562100663b4179C95E5B199576f2E16b150e"
    },
    {
      name: "JoeUsdc",
      snowglobe: "0x8C9fAEBD41c68B801d628902EDad43D88e4dD0a6"
    },
    {
      name: "JoeUsdt",
      snowglobe: "0xc7Ca863275b2D0F7a07cA6e2550504362705aA1A"
    },
    {
      name: "JoeWbtc",
      snowglobe: "0xfb49ea67b84F7c1bBD825de7febd2C836BC4B47E"
    },
    {
      name: "JoeEth",
      snowglobe: "0x49e6A1255DEfE0B194a67199e78aD5AA5D7cb092"
    },
    {
      name: "JoeMim",
      snowglobe: "0x3aAF997FdDA51eBb0918e3E59021f5FDE52444d8"
    },
    {
      name: "JoeXJoe",
      snowglobe: "0x6a52e6b23700A63eA4a0Db313eBD386Fb510eE3C"
    },
  ];

  const Council = new ethers.Contract(council_addr, multisig_ABI, signer);
  const iMultiSig = new ethers.utils.Interface(multisig_ABI);
  const iSnowGlobe = new ethers.utils.Interface(snowglobe_ABI);
  const controller_addr = "0xF2FA11Fc9247C23b3B622C41992d8555f6D01D8f";

  const withdrawFromPool = async pool => {

    const first_encoding = iSnowGlobe.encodeFunctionData("setController", [controller_addr]);

    const second_encoding = iMultiSig.encodeFunctionData("submitTransaction", [pool.snowglobe, 0, first_encoding]);
    
    // var options = { gasPrice: 25000000000, gasLimit: 8000000 };
    const submission = await Council.submitTransaction(treasury_addr, 0, second_encoding);
    const tx_submission = await submission.wait(1);
    if (!tx_submission.status) {
      console.error(`Error submitting transaction: setController for ${pool.name}`);
      return;
    }
    console.log(`transaction submitted: setController for ${pool.name}`);

    return;
  };  

  for (const pool of pools) {
    await withdrawFromPool(pool);
  }

  return;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });