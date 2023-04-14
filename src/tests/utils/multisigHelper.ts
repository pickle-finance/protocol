import { SafeTransactionDataPartial, SafeTransaction } from "@safe-global/safe-core-sdk-types";
import Safe from "@safe-global/safe-core-sdk";
import EthersAdapter from "@safe-global/safe-ethers-lib";
import { config, ethers, run } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { deployContract, unlockAccount } from "./testHelper";
import { writeFileSync } from "fs";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { setBalance } from "@nomicfoundation/hardhat-network-helpers";

/**
 * @notice takes a gnosis safe address and returns a list of Safe instances each with a unique owner,
 * the length of the array is the minimum threshold needed to execute a gnosis safe transaction
 */
const getSafesWithOwners = async (safeAddress: string): Promise<Safe[]> => {
  // prettier-ignore
  const safeAbi = ["function getOwners() view returns(address[])", "function getThreshold() view returns(uint256)"];
  const safeContract = new ethers.Contract(safeAddress, safeAbi, await ethers.getSigners().then((x) => x[0]));
  const ownersAddresses: string[] = await safeContract.getOwners();
  const threshold = await safeContract.getThreshold().then((x: BigNumber) => x.toNumber());
  const neededOwnersAddresses = ownersAddresses.slice(0, threshold);

  const ethAdapters: EthersAdapter[] = await Promise.all(
    neededOwnersAddresses.map(async (ownerAddr) => new EthersAdapter({ ethers, signerOrProvider: await unlockAccount(ownerAddr) }))
  );

  const safeWithOwners: Safe[] = await Promise.all(
    ethAdapters.map(async (ethAdapter) => await Safe.create({ safeAddress, ethAdapter }))
  );

  return safeWithOwners;
};
/**
 * @param targetContract the target contract
 * @param funcName the target function name on the contract. (e.g, "transfer")
 * @param funcArgs the arguments of the target function (e.g, ["0x000...",BigNumber.from("10000000000")]
 */
const getSafeTxnData = (targetContract: Contract, funcName: string, funcArgs: any[]) => {
  const data = targetContract.interface.encodeFunctionData(funcName, funcArgs);
  const safeTransactionData: SafeTransactionDataPartial = {
    to: targetContract.address,
    data,
    value: "0",
    safeTxGas: 1800000,
  };
  return safeTransactionData;
};

const getSafeToProxyTxnData = (targetContract: Contract, funcName: string, funcArgs: any[]) => {
  const data = targetContract.interface.encodeFunctionData(funcName, funcArgs);
  const safeTransactionData: SafeTransactionDataPartial = {
    to: targetContract.address,
    data,
    value: "0",
    safeTxGas: 1800000,
  };
  return safeTransactionData;
};

const executeSafeTxn = async (safeTransactionData: SafeTransactionDataPartial, safesWithOwners: Safe[]) => {
  const safeTxn: SafeTransaction = await safesWithOwners[0].createTransaction({ safeTransactionData });
  const txHash = await safesWithOwners[0].getTransactionHash(safeTxn);

  // Ensure owner has enough eth to execute txns
  const minBalance = ethers.utils.parseEther("0.1");
  const ownerAddress = await safesWithOwners[0].getEthAdapter().getSignerAddress();
  const ownerBalance = await safesWithOwners[0].getEthAdapter().getBalance(ownerAddress);
  if (ownerBalance.lt(minBalance)) {
    await setBalance(ownerAddress, minBalance.mul(2));
  }

  await Promise.all(
    safesWithOwners.map(async (safe) => await (await safe.approveTransactionHash(txHash)).transactionResponse?.wait())
  );

  return safesWithOwners[0].executeTransaction(safeTxn).then((x) => x.transactionResponse.wait());
};

const writeProxyToFile = (proxyContract: Contract, funcName: string) => {
  const convert = (funcSignature: string, argsNames: string[], withTypes: boolean) => {
    let result = funcSignature;
    let index = 0;
    for (let i = 0; i < argsNames.length; i++) {
      const argName = argsNames[i];

      let startIndex = result.indexOf("(", index);
      if (startIndex === -1) {
        startIndex = result.indexOf(",", index);
      }

      let endIndex = result.indexOf(",", startIndex + 1);
      if (endIndex === -1) {
        endIndex = result.indexOf(")", startIndex + 1);
      }

      const type = result.substring(startIndex + 1, endIndex);
      const typeStr = withTypes ? type + " " : "";
      result = result.substring(0, startIndex + 1) + typeStr + argName + result.substring(endIndex);
      index = startIndex + 1;
    }
    return result;
  };

  const funcSignature = Object.keys(proxyContract.interface.functions).find((f) => f.startsWith(funcName));
  const nArgs = (funcSignature.match(/,/g) || []).length;
  const alpha = Array.from(Array(nArgs + 1)).map((_, i) => i + 65);
  const argsNames = alpha.map((x) => String.fromCharCode(x).toLowerCase());

  const funcSigWithNames = convert(funcSignature, argsNames, true);
  const funcSigWithoutTypes = convert(funcSignature, argsNames, false);

  const code = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


interface ITarget {
 function ${funcSignature} external;
}

contract Proxy {
    function ${funcSigWithNames} external {
        ITarget(${ethers.utils.getAddress(proxyContract.address)}).${funcSigWithoutTypes};
    }
}`;
  writeFileSync("src/tmp/proxy.sol", code);
};

const compileDir = async (dirPath: string) => {
  // Limit Hardhat to only compile the supplied dir
  const oldSourcesPath = config.paths.sources;
  config.paths.sources = dirPath;
  await run("compile");
  config.paths.sources = oldSourcesPath;
};

export const sendGnosisSafeTxn = async (
  safeAddress: string,
  targetContract: Contract,
  funcName: string,
  funcArgs: any[]
) => {
  const safesWithOwners = await getSafesWithOwners(safeAddress);
  const txnData = getSafeTxnData(targetContract, funcName, funcArgs);
  const txnReceipt = await executeSafeTxn(txnData, safesWithOwners);
  return txnReceipt;
};

export const sendGnosisSafeProxyTxn = async (
  safeAddress: string,
  targetContract: Contract,
  targetFuncName: string,
  targetFuncArgs: any[],
  proxyContract: Contract,
  proxyFuncName: string
) => {
  writeProxyToFile(proxyContract, proxyFuncName);
  await compileDir("src/tmp");
  const proxyContract1 = await deployContract("src/tmp/proxy.sol:Proxy");
  targetFuncArgs[0] = proxyContract1.address;
  return sendGnosisSafeTxn(safeAddress, targetContract, targetFuncName, targetFuncArgs);
};

export const callExecuteToProxy = async (
  permissionedSigner: SignerWithAddress,
  executeContract: Contract,
  targetContract: Contract,
  targetFuncName: string,
  targetFuncArgs: any[],
) => {
  writeProxyToFile(targetContract, targetFuncName);
  await compileDir("src/tmp");
  const proxyContract1 = await deployContract("src/tmp/proxy.sol:Proxy");
  const txnData = proxyContract1.interface.encodeFunctionData(targetFuncName, targetFuncArgs);
  return await executeContract.connect(permissionedSigner).execute(proxyContract1.address, txnData).then(x=>x.wait());
}
