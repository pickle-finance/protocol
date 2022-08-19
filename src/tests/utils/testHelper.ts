import "@nomicfoundation/hardhat-toolbox";
import { BigNumber, BigNumberish, providers } from "ethers";
import { ethers, network } from "hardhat";
import * as chai from 'chai';


/**
 * @notice travel the time to test the block.timestamp
 */
export const increaseTime = async (sec: number) => {
  if (sec < 60) console.log(`⌛ Advancing ${sec} secs`);
  else if (sec < 3600) console.log(`⌛ Advancing ${Number(sec / 60).toFixed(0)} mins`);
  else if (sec < 60 * 60 * 24) console.log(`⌛ Advancing ${Number(sec / 3600).toFixed(0)} hours`);
  else if (sec < 60 * 60 * 24 * 31) console.log(`⌛ Advancing ${Number(sec / 3600 / 24).toFixed(0)} days`);

  await network.provider.send("evm_increaseTime", [sec]);
  await network.provider.send("evm_mine");
};

/**
 * @notice increase the block to test the block.number
 */
export const increaseBlock = async (block: number) => {
  console.log(`⌛ Advancing ${block} blocks`);
  for (let i = 1; i <= block; i++) {
    await network.provider.send("evm_mine");
  }
};

/**
 * @notice deploy the contract with the name and arguments
 */
export const deployContract = async (name: string, ...arg: any[]) => {
  const contractFactory = await ethers.getContractFactory(name);
  const contract = await contractFactory.deploy(...arg);
  await contract.deployed();
  return contract;
};

/**
 * @notice get the contract instance from the address and contract name
 */
export const getContractAt = async (name: string, address: string) => {
  return await ethers.getContractAt(name, address);
};

/**
 * @notice get the signer to impersonate
 */
export const unlockAccount = async (
  address: string
): Promise<providers.JsonRpcSigner> => {
  await network.provider.send("hardhat_impersonateAccount", [address]);
  return ethers.provider.getSigner(address);
};

/**
 * @notice get the parsed bignumber from the decimals
 */
export const toWei = (amount: number, decimal = 18) => {
  return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimal));
};

/**
 * @notice convert bignumber into human-readable string
 */
export const fromWei = (amount: BigNumberish, decimal = 18) => {
  return ethers.utils.formatUnits(amount, decimal);
};

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
export const NULL_ADDRESS = "0x0000000000000000000000000000000000000001";

/**
 * @notice add new assertion method to chai
 */
chai.use((_chai) => {
  let Assertion = _chai.Assertion;
  Assertion.addMethod('eqApprox', function (amount) {
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
});

export const expect = chai.expect;

