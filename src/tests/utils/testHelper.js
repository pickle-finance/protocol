const hre = require("hardhat");
const {BigNumber: BN} = require("ethers");

var chaiAsPromised = require("chai-as-promised");
const {expect, Assertion} = require("chai").use(chaiAsPromised);

/**
 * @notice travel the time to test the block.timestamp
 * @param sec sec to be traveled
 */
const increaseTime = async (sec) => {
  console.log(`advancing ${Number(sec / 60).toFixed(2)} mins`);
  await hre.network.provider.send("evm_increaseTime", [sec]);
  await hre.network.provider.send("evm_mine");
};

/**
 * @notice increase the block to test the block.number
 * @param sec block count to be traveled
 */
const increaseBlock = async (block) => {
  console.log(`advancing ${block} blocks`);
  for (let i = 1; i <= block; i++) {
    await hre.network.provider.send("evm_mine");
  }
};

/**
 * @notice deploy the contract with the name and arguments
 * @param name name of the contract
 * @param arg list of arguments to be used for constructor
 * @returns contract instance
 */
const deployContract = async (name, ...arg) => {
  const contractFactory = await hre.ethers.getContractFactory(name);
  const contract = await contractFactory.deploy(...arg);
  await contract.deployed();
  return contract;
};

/**
 * @notice get the contract instance from the address and contract name
 * @param name contract name
 * @param address contract address
 * @returns contract instance
 */
const getContractAt = async (name, address) => {
  return await hre.ethers.getContractAt(name, address);
};

/**
 * @notice get the signer to impersonate
 * @param address address to impersonate
 * @returns signer
 */
const unlockAccount = async (address) => {
  await hre.network.provider.send("hardhat_impersonateAccount", [address]);
  return hre.ethers.provider.getSigner(address);
};

/**
 * @notice get the parsed bignumber from the decimals
 * @param amount amount to be converted
 * @param decimal
 * @returns parsed bignumber
 */
const toWei = (amount, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(decimal));
};

/**
 * @notice get the parsed bignumber from the decimals
 * @param amount amount to be converted
 * @param decimal
 * @returns parsed big number
 */
const fromWei = (amount, decimal = 18) => {
  return hre.ethers.utils.formatUnits(amount, decimal);
};

/**
 * @notice add the method to expect to compare approximately
 */
Assertion.addMethod("eqApprox", function (amount) {
  let obj = this._obj;
  const min = amount.mul(95).div(100);
  const max = amount.mul(105).div(100);
  this.assert(
    obj.gt(min) && obj.lt(max),
    "expected #{this} to be equal approx with #{exp} but got #{act}",
    "expected #{this} to not equal approx with #{exp}",
    amount.toString(), // expected
    obj.toString() // actual
  );
});

module.exports = {
  expect,
  increaseBlock,
  increaseTime,
  deployContract,
  getContractAt,
  unlockAccount,
  toWei,
  fromWei,
};
