import "@nomicfoundation/hardhat-toolbox";
import {TransactionReceipt} from "@ethersproject/providers";
import {ethers, run, config} from "hardhat";
import "./flat";
import {writeFileSync} from "fs";
import {ConstructorArguments, OBJECT_FILE_NAME} from "./constants";

/**
 * @param controllerContract example: "src/optimism/controller-v7.sol:ControllerV7"
 */
export const deployController = async (
  controllerContract: string,
  governance: string,
  strategist: string,
  timelock: string,
  devfund: string,
  treasury: string
) => {
  return flatDeployAndVerifyContract(controllerContract, [governance, strategist, timelock, devfund, treasury]);
};

/**
 * @param {string} strategyContract example: "src/strategies/optimism/velodrome/strategy-velo-op-vlp.sol:StrategyVeloOpVlp"
 */
export const deployStrategy = async (
  strategyContract: string,
  governance: string,
  strategist: string,
  controller: string,
  timelock: string
) => {
  return flatDeployAndVerifyContract(strategyContract, [governance, strategist, controller, timelock]);
};

/**
 * @param {string} strategyContract example: "src/strategies/optimism/velodrome/strategy-velo-op-vlp.sol:StrategyVeloOpVlp"
 * @param tickMultiplier multiplier for the tick range
 */
export const deployStrategyV3 = async (
  strategyContract: string,
  tickMultiplier: number,
  governance: string,
  strategist: string,
  controller: string,
  timelock: string
) => {
  return flatDeployAndVerifyContract(strategyContract, [tickMultiplier, governance, strategist, controller, timelock]);
};

/**
 * Jar contracts only need to be verified once, every subsequent jar deployment gets verified automatically
 * This function will not attempt verification, use `verifyJar()` for that
 * @param {string} jarContract example: "src/pickle-jar.sol:PickleJar"
 */
export const deployJar = async (
  jarContract: string,
  want: string,
  governance: string,
  timelock: string,
  controller: string
) => {
  return flatDeployAndVerifyContract(jarContract, [want, governance, timelock, controller], true, false);
};

/**
 * Jar contracts only need to be verified once, every subsequent jar deployment gets verified automatically
 * This function will not attempt verification, use `verifyJar()` for that
 * @param {string} jarContract example: `src/optimism/pickle-jar-univ3.sol:PickleJarUniV3Optimism`
 */
export const deployJarV3 = async (
  jarContract: string,
  jarName: string,
  jarSymbol: string,
  pool: string,
  native: string,
  governance: string,
  timelock: string,
  controller: string
) => {
  return flatDeployAndVerifyContract(
    jarContract,
    [jarName, jarSymbol, pool, native, governance, timelock, controller],
    true,
    false
  );
};

/**
 * @param jarFlattenedContract use the flattened contract path. example: `src/tmp/pickle-jar.sol:PickleJar`
 */
export const verifyJar = async (
  jarFlattenedContract: string,
  jarAddr: string,
  want: string,
  governance: string,
  timelock: string,
  controller: string
) => {
  return verifyContract(jarFlattenedContract, jarAddr, [want, governance, timelock, controller]);
};

/**
 * @param strategyFlattenedContract use the flattened contract path. example `src/tmp/strategy-velo-op-vlp.sol:StrategyVeloOpVlp`
 */
export const verifyStrategy = async (
  strategyFlattenedContract: string,
  strategyAddr: string,
  governance: string,
  strategist: string,
  controller: string,
  timelock: string
) => {
  return verifyContract(strategyFlattenedContract, strategyAddr, [governance, strategist, controller, timelock]);
};

export const flatDeployAndVerifyContract = async (
  contract: string,
  constructorArguments: ConstructorArguments,
  flatten: boolean = true,
  verify: boolean = true
) => {
  // Flatten
  const flattened = flatten ? await flattenContract(contract) : contract;

  // Deploy
  const receipt = await deployContract(flattened, constructorArguments);
  const contractName = flattened.substring(flattened.lastIndexOf(":" + 1));

  // Verify
  if (verify) {
    const verificationSuccessfull = await verifyContract(flattened, receipt.contractAddress, constructorArguments);
    if (!verificationSuccessfull)
      console.log("❌❌ Verification failed!\n\tContract: " + contractName + "\n\tAddress: " + receipt.contractAddress);
  }
  return receipt.contractAddress;
};

export const deployContract = async (
  contract: string,
  constructorArguments: ConstructorArguments
): Promise<TransactionReceipt> => {
  const contractFactory = await ethers.getContractFactory(contract);
  const txn = await contractFactory.deploy(...constructorArguments);
  return txn.deployTransaction.wait();
};

export const flattenContract = async (contract: string) => {
  const path = contract.substring(0, contract.lastIndexOf(":"));
  const fileName = path.substring(path.lastIndexOf("/"));
  const contractName = contract.substring(contract.lastIndexOf(":"));
  await run("flat", {
    files: [path],
    output: "src/tmp" + fileName,
  });

  // Compile the flattened contract
  // Limit Hardhat to only compile the flattened contracts path
  const oldSourcesPath = config.paths.sources;
  config.paths.sources = "src/tmp";
  await run("compile");
  config.paths.sources = oldSourcesPath;
  const flattenedContract = "src/tmp" + fileName + contractName;

  return flattenedContract;
};

export const verifyContract = async (
  contract: string,
  address: string,
  constructorArguments: ConstructorArguments
): Promise<boolean> => {
  try {
    await sleep(10); // wait for etherscan to index the new contract
    await run("verify:verify", {
      contract: contract,
      address: address,
      constructorArguments: constructorArguments,
    });
    return true;
  } catch (e) {
    console.error(e);
    return false;
  }
};

export const sleep = async (seconds: number) => {
  console.log(`Sleeping for ${seconds}s...`);
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
};

export const persistify = (deploymentStateObject) => {
  const stringified = JSON.stringify(deploymentStateObject, null, 4);
  writeFileSync(__dirname.concat("/").concat(OBJECT_FILE_NAME), stringified);
};
