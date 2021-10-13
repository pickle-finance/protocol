const hre = require("hardhat");
const {BigNumber: BN} = require("ethers");

var chaiAsPromised = require("chai-as-promised");
const {expect, Assertion} = require("chai").use(chaiAsPromised);

const increaseTime = async (sec) => {
  // if (sec < 60) console.log(`⌛ Advancing ${sec} secs`);
  // else if (sec < 3600) console.log(`⌛ Advancing ${Number(sec / 60).toFixed(0)} mins`);
  // else if (sec < 60 * 60 * 24) console.log(`⌛ Advancing ${Number(sec / 3600).toFixed(0)} hours`);
  // else if (sec < 60 * 60 * 24 * 31) console.log(`⌛ Advancing ${Number(sec / 3600 / 24).toFixed(0)} days`);

  await hre.network.provider.send("evm_increaseTime", [sec]);
  await hre.network.provider.send("evm_mine");
};

const increaseBlock = async (block) => {
  //console.log(`⌛ Advancing ${block} blocks`);
  for (let i = 1; i <= block; i++) {
    await hre.network.provider.send("evm_mine");
  }
};

const toWei = (amount, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(decimal));
};

const fromWei = (amount) => {
  return amount.div(1000000000000000000).toString();
};

const toGwei = (amount) => {
  return amount.div(1000000000).toString();
};

const overwriteTokenAmount = async (assetAddr, walletAddr,amount, slot =0) => {
    const index = ethers.utils.solidityKeccak256(["uint256", "uint256"],[walletAddr, slot]);
    const BN = ethers.BigNumber.from(amount)._hex.toString();
    const number = ethers.utils.hexZeroPad(BN,32);

    await ethers.provider.send("hardhat_setStorageAt", [assetAddr, index, number]);
    await hre.network.provider.send("evm_mine");
};

const returnSigner = async (address) => {
  await network.provider.send('hardhat_impersonateAccount', [address]);
  return ethers.provider.getSigner(address)
}

module.exports = {
    toWei,
    fromWei,
    toGwei,
    increaseBlock,
    increaseTime,
    overwriteTokenAmount,
    returnSigner
  };