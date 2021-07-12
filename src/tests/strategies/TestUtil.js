const hre = require("hardhat");
const {BigNumber: BN} = require("ethers");

var chaiAsPromised = require("chai-as-promised");
const {expect, Assertion} = require("chai").use(chaiAsPromised);

const increaseTime = async (sec) => {
  console.log(`advancing ${Number(sec / 60).toFixed(2)} mins`);
  await hre.network.provider.send("evm_increaseTime", [sec]);
  await hre.network.provider.send("evm_mine");
};

const increaseBlock = async (block) => {
  console.log(`advancing ${count} blocks`);
  for (let i = 1; i <= block; i++) {
    await hre.network.provider.send("evm_mine");
  }
};

const deployContract = async (name, ...arg) => {
  const contractFactory = await hre.ethers.getContractFactory(name);
  const contract = await contractFactory.deploy(...arg);
  await contract.deployed();
  return contract;
};

const getContractAt = async (name, address) => {
  return await hre.ethers.getContractAt(name, address);
};

const unlockAccount = async (address) => {
  await hre.network.provider.send("hardhat_impersonateAccount", [address]);
  return hre.ethers.provider.getSigner(address);
};

const toWei = (amount, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(decimal));
};

const fromWei = (amount, decimal = 18) => {
  return hre.ethers.utils.formatUnits(amount, decimal);
};

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const NULL_ADDRESS = "0x0000000000000000000000000000000000000001";

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
  ZERO_ADDRESS,
  NULL_ADDRESS,
};
