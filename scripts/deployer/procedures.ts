import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { TransactionReceipt, TransactionResponse } from "@ethersproject/providers";
import stateObjectJson from "./deployment-state-object.json"; // deployment state object
import {
  deployJar,
  deployJarV3,
  deployStrategy,
  deployStrategyV3,
  flatDeployAndVerifyContract,
  persistify,
  sleep,
  verifyContract,
  verifyJar,
} from "./utils";
import { ADDRESSES, ChainAddresses, DeploymentStateObject } from "./constants";

const stateObject: DeploymentStateObject = stateObjectJson;

export const deployPickleTokenAnyswap = async () => {
  const tokenContract = "src/optimism/pickle-token.sol:AnyswapV6ERC20";
  const name = "PickleToken";
  const symbol = "PICKLE";
  const decimals = 18;
  const vault = await ethers.getSigners().then((x) => x[0].address);
  const underlying = ethers.constants.AddressZero;
  const constructorArgs = [name, symbol, decimals, underlying, vault];

  const tokenAddress = await flatDeployAndVerifyContract(tokenContract, constructorArgs, false);
  console.log(`PickleToken Successfully deployed at ${tokenAddress}`);
}

export const deployStratAndJar = async (
  strategyContract: string,
  jarContract: string,
  chainAddresses: ChainAddresses
) => {
  const deployer = await ethers.getSigners().then((x) => x[0]);
  console.log(`Deployer: ${deployer.address}`);

  const name = strategyContract.substring(
    strategyContract.lastIndexOf(":") + 1
  );

  let strategy: Contract | undefined, jar: Contract | undefined;

  // Retrieve deployed contracts if present
  if (stateObject[name]) {
    const stratAddr = stateObject[name].strategy;
    const jarAddr = stateObject[name].jar;
    if (stratAddr) {
      strategy = await ethers.getContractAt(strategyContract, stratAddr);
    }
    if (jarAddr) {
      jar = await ethers.getContractAt(jarContract, jarAddr);
    }
  } else {
    stateObject[name] = { name: name };
  }

  persistify(stateObject);

  let deploymentSuccess = false;
  try {
    if (!strategy) {
      // Deploy Strategy contract
      console.log(`\nDeploying ${name}...`);
      const strategyAddr = await deployStrategy(
        strategyContract,
        chainAddresses.governance,
        chainAddresses.strategist,
        chainAddresses.controller,
        chainAddresses.timelock
      );

      stateObject[name].strategy = strategyAddr;
      persistify(stateObject);
      strategy = await ethers.getContractAt(strategyContract, strategyAddr);
      console.log(`✔️ Strategy deployed at: ${strategy.address}`);
    }

    // TODO: Check for deployer address want balance

    if (!jar) {
      // Get Want details
      const want: string = await strategy.want();
      stateObject[name].want = want;

      // Deploy PickleJar contract
      console.log("\nDeploying jar...");

      const jarAddr = await deployJar(
        jarContract,
        want,
        chainAddresses.governance,
        chainAddresses.timelock,
        chainAddresses.controller
      );
      stateObject[name].jar = jarAddr;
      persistify(stateObject);
      jar = await ethers.getContractAt(jarContract, jarAddr);
      console.log(`✔️ PickleJar deployed at: ${jar.address}`);
    }

    if (!stateObject[name].wantApproveTx) {
      // Log Want
      const want = await ethers.getContractAt(
        "src/lib/erc20.sol:ERC20",
        await strategy.want()
      );
      console.log(`Want address is: ${stateObject[name].want}`);

      // Approve want for deposit
      console.log(`Approving token0 for deposit...`);
      const wantApproveTx: TransactionReceipt = await (
        await want.approve(jar?.address, ethers.constants.MaxUint256)
      ).wait();
      stateObject[name].wantApproveTx = wantApproveTx.transactionHash;
      persistify(stateObject);
      console.log(`✔️ Successfully approved Jar to spend want`);
    }
    deploymentSuccess = true;
  } catch (e) {
    console.log(`❌❌ Oops something went wrong...`);
    console.error(e);
  }
  // Deployment Report
  const report = `
    ${stateObject[name].name} - ${deploymentSuccess ? "Fully Deployed" : "DEPLOYMENT FAILED!"
    }
    jar:${stateObject[name].jar}
    want:${stateObject[name].want}
    strategy:${stateObject[name].strategy}
    ----------------------------
    `;
  console.log(report);
  return deploymentSuccess;
};

export const testStratAndJar = async (
  strategyContract: string,
  jarContract: string,
  controllerContract: string
) => {
  let testSuccessful = false;
  const deployer = await ethers.getSigners().then(x => x[0]);

  const name = strategyContract.substring(
    strategyContract.lastIndexOf(":") + 1
  );
  console.log(`Deployer: ${deployer.address} Strategy: ${name}`);

  if (!(stateObject[name] && stateObject[name].strategy && stateObject[name].jar && stateObject[name].want && stateObject[name].wantApproveTx))
    throw `❌❌ ${name} is not fully deployed!`;

  const strategy = await ethers.getContractAt(
    strategyContract,
    stateObject[name].strategy
  );
  const jar = await ethers.getContractAt(jarContract, stateObject[name].jar);
  const want = await ethers.getContractAt("src/lib/erc20.sol:ERC20", stateObject[name].want);
  const controller = await ethers.getContractAt(
    controllerContract,
    await jar.controller()
  );


  if (!stateObject[name].depositTx) {
    const wantAllowance: BigNumber = await want.allowance(deployer.address, jar.address);
    const deployerBalance: BigNumber = await want.balanceOf(deployer.address);

    // Sanity checks
    if (deployerBalance.eq("0") || wantAllowance.lt(deployerBalance)) {
      throw `❌❌ jar cannot spend tokens from deployer address!\n\twant allowance: ${wantAllowance.toString()}\n\tdeployer balance: ${deployerBalance.toString()}`;
    }
    if ((await controller.jars(want.address)) != jar.address)
      throw "❌❌ jar is not set on the controller!";
    if ((await controller.strategies(want.address)) != strategy.address)
      throw "❌❌ strategy is not set on the controller!";
    // Initial deposit
    console.log("\nDepositing in jar...");
    try {
      const estimate = await jar.estimateGas.deposit(deployerBalance);
      const opts = { gasLimit: estimate.mul(2) };
      const receipt: TransactionReceipt = await jar.deposit(deployerBalance, opts).then((x: TransactionResponse) => x.wait());
      stateObject[name].depositTx = receipt.transactionHash;
      persistify(stateObject);
      console.log("✔️ Want deposited successfully");
    } catch (error) {
      console.log("❌❌ failed depositing want into the jar!");
      throw error;
    }
  }

  if (!stateObject[name].earnTx) {
    // Deposit Want
    console.log("\nCalling earn on Jar...");
    const estimate = await jar.estimateGas.earn();
    const opts = { gasLimit: estimate.mul(2) };
    const receipt: TransactionReceipt = await jar.earn(opts).then((x: TransactionResponse) => x.wait());
    stateObject[name].earnTx = receipt.transactionHash;
    persistify(stateObject);
    console.log("✔️ Earn called successfully");
  }

  if (!stateObject[name].harvestTx) {
    // Harvest
    const ratioBefore = await jar.getRatio();
    console.log(
      `\nWaiting for 60s before harvesting...`
    );
    await sleep(60);
    console.log("Calling harvest...");
    const estimate = await strategy.estimateGas.harvest();
    const opts = { gasLimit: estimate.mul(2) };
    const receipt: TransactionReceipt = await strategy.harvest(opts).then((x: TransactionResponse) => x.wait());
    await sleep(10);
    const ratioAfter = await jar.getRatio();

    if (ratioAfter.gt(ratioBefore)) {
      console.log(`✔️ Harvest was successful`);
      stateObject[name].harvestTx = receipt.transactionHash;
      persistify(stateObject);
    } else {
      throw (`❌❌ Harvest failed, ratio has not increased`);
    }
  }
  testSuccessful = true;

  // Script Report
  const report = `
     ${stateObject[name].name} - ${stateObject[name].harvestTx ? "Fully Tested" : "TEST FAILED!"
    }
     jar:${stateObject[name].jar}
     want:${stateObject[name].want}
     strategy:${stateObject[name].strategy}
     ----------------------------
     `;
  console.log(report);
  return testSuccessful;
};

// TODO fix this one
export const deployStratAndJarV3 = async (
  strategyContract: string,
  jarContract: string,
  tickMultiplier: number,
  chainAddresses: ChainAddresses
) => {
  const deployer = await ethers.getSigners().then((x) => x[0]);
  console.log(`Deployer: ${deployer.address}`);

  const name = strategyContract.substring(
    strategyContract.lastIndexOf(":") + 1
  );

  let strategy: Contract | undefined, jar: Contract | undefined;

  // Retrieve deployed contracts if present
  if (stateObject[name]) {
    const stratAddr = stateObject[name].strategy;
    const jarAddr = stateObject[name].jar;
    if (stratAddr) {
      strategy = await ethers.getContractAt(strategyContract, stratAddr);
    }
    if (jarAddr) {
      jar = await ethers.getContractAt(jarContract, jarAddr);
    }
  } else {
    stateObject[name] = { name: name };
  }

  persistify(stateObject);

  let deploymentSuccess = false;
  try {
    if (!strategy) {
      // Deploy Strategy contract
      console.log(`\nDeploying ${name}...`);
      const strategyAddr = await deployStrategyV3(
        strategyContract,
        tickMultiplier,
        chainAddresses.governance,
        chainAddresses.strategist,
        chainAddresses.controller,
        chainAddresses.timelock
      );

      stateObject[name].strategy = strategyAddr;
      persistify(stateObject);
      strategy = await ethers.getContractAt(strategyContract, strategyAddr);
      console.log(`✔️ Strategy deployed at: ${strategy.address}`);
    }

    // TODO: Check for deployer address want balance

    if (!jar) {
      // Get Want details
      const want: string = await strategy.pool();
      stateObject[name].want = want;

      const token0 = await ethers.getContractAt(
        "src/lib/erc20.sol:ERC20",
        await strategy.token0()
      );
      const token1 = await ethers.getContractAt(
        "src/lib/erc20.sol:ERC20",
        await strategy.token1()
      );
      const native = await ethers.getContractAt(
        "src/lib/erc20.sol:ERC20",
        await strategy.native()
      );
      const token0Symbol = await token0.symbol();
      const token1Symbol = await token1.symbol();

      // Deploy PickleJar contract
      console.log("\nDeploying jar...");

      const jarName = `pickling ${token0Symbol}/${token1Symbol} Jar`;
      const jarSymbol = `p${token0Symbol}${token1Symbol}`;

      const jarAddr = await deployJarV3(
        jarContract,
        jarName,
        jarSymbol,
        want,
        native.address,
        chainAddresses.governance,
        chainAddresses.timelock,
        chainAddresses.controller
      );
      stateObject[name].jar = jarAddr;
      persistify(stateObject);
      jar = await ethers.getContractAt(jarContract, jarAddr);
      console.log(`✔️ PickleJar deployed at: ${jar.address}`);
    }

    let wantTokensApproved: boolean = !!(
      stateObject[name].token0ApproveTx && stateObject[name].token1ApproveTx
    );
    if (!wantTokensApproved) {
      // Log Want
      const token0 = await ethers.getContractAt(
        "src/lib/erc20.sol:ERC20",
        await strategy.token0()
      );
      const token1 = await ethers.getContractAt(
        "src/lib/erc20.sol:ERC20",
        await strategy.token1()
      );
      console.log(`Pool address is: ${stateObject[name].want}`);
      console.log(`Token0 address: ${token0.address}`);
      console.log(`Token1 address: ${token1.address}`);

      // Approve tokens for deposit
      if (!stateObject[name].token0ApproveTx) {
        console.log(`Approving token0 for deposit...`);
        const approveToken0Tx: TransactionReceipt = await (
          await token0.approve(jar?.address, ethers.constants.MaxUint256)
        ).wait();
        stateObject[name].token0ApproveTx = approveToken0Tx.transactionHash;
        persistify(stateObject);
        console.log(`✔️ Successfully approved Jar to spend token0`);
      }
      if (!stateObject[name].token1ApproveTx) {
        console.log(`Approving token1 for deposit...`);
        const approveToken1Tx: TransactionReceipt = await (
          await token1.approve(jar?.address, ethers.constants.MaxUint256)
        ).wait();
        stateObject[name].token1ApproveTx = approveToken1Tx.transactionHash;
        persistify(stateObject);
        console.log(`✔️ Successfully approved Jar to spend token1`);
      }
    }
    deploymentSuccess = true;
  } catch (e) {
    console.log(`❌❌ Oops something went wrong...`);
    console.error(e);
  }
  // Deployment Report
  const report = `
    ${stateObject[name].name} - ${deploymentSuccess ? "Fully Deployed" : "DEPLOYMENT FAILED!"
    }
    jar:\t${stateObject[name].jar}
    want:\t${stateObject[name].want}
    strategy:\t${stateObject[name].strategy}
    ----------------------------
    `;
  console.log(report);
};


// TODO fix this one
//export const testStratAndJarV3 = async (
//  strategyContract: string,
//  jarContract: string,
//  controllerContract: string
//) => {
//  const deployer = await ethers.getSigners().then(x => x[0]);
//  console.log(`Deployer: ${deployer.address}`);
//
//  const name = strategyContract.substring(
//    strategyContract.lastIndexOf(":") + 1
//  );
//  const strategy = await ethers.getContractAt(
//    strategyContract,
//    stateObject[name].strategy
//  );
//  const jar = await ethers.getContractAt(jarContract, stateObject[name].jar);
//  const controller = await ethers.getContractAt(
//    controllerContract,
//    await jar.controller()
//  );
//  const poolAddr = await jar.pool();
//
//  const token0 = await ethers.getContractAt(
//    "src/lib/erc20.sol:ERC20",
//    await strategy.token0()
//  );
//  const token1 = await ethers.getContractAt(
//    "src/lib/erc20.sol:ERC20",
//    await strategy.token1()
//  );
//
//  const t0Allowance = await token0.allowance(deployer.address, jar.address);
//  const t1Allowance = await token1.allowance(deployer.address, jar.address);
//
//  // Sanity checks
//  if (t0Allowance.eq("0") || t1Allowance.eq("0")) {
//    throw `❌❌ jar cannot spend tokens from deployer address!\ntoken0 allowance: ${t0Allowance.toString()}\ntoken1 allowance: ${t1Allowance.toString()}`;
//  }
//  if ((await controller.jars(poolAddr)) != jar.address)
//    throw "❌❌ jar is not set on the controller!";
//  if ((await controller.strategies(poolAddr)) != strategy.address)
//    throw "❌❌ strategy is not set on the controller!";
//
//  if (!stateObject[name].rebalanceTx) {
//    // Initial position
//    console.log("\nMinting initial position...");
//    const t0Balance = await token0.balanceOf(deployer.address);
//    const t1Balance = await token1.balanceOf(deployer.address);
//    try {
//      if (!stateObject[name].initToken0DepositTx) {
//        console.log("Sending token0 to the strategy...");
//        const initToken0DepositTx = await executeTx(callAttempts, () =>
//          token0.transfer(
//            strategy.address,
//            t0Balance.mul(BigNumber.from("20")).div(BigNumber.from(100))
//          )
//        );
//        if (initToken0DepositTx?.transactionHash) {
//          stateObject[name].initToken0DepositTx =
//            initToken0DepositTx.transactionHash;
//          persistify(stateObject);
//        }
//      }
//      if (!stateObject[name].initToken1DepositTx) {
//        console.log("Sending token1 to the strategy...");
//        const initToken1DepositTx = await executeTx(callAttempts, () =>
//          token1.transfer(
//            strategy.address,
//            t1Balance.mul(BigNumber.from("20")).div(BigNumber.from(100))
//          )
//        );
//        if (initToken1DepositTx?.transactionHash) {
//          stateObject[name].initToken1DepositTx =
//            initToken1DepositTx.transactionHash;
//          persistify(stateObject);
//        }
//      }
//    } catch (error) {
//      throw "❌❌ failed transfering one of the tokens to strategy!";
//    }
//    console.log("Calling rebalance on the strategy...");
//    const rebalanceTx = await executeTx(callAttempts, () =>
//      strategy.rebalance()
//    );
//    if (rebalanceTx?.transactionHash) {
//      stateObject[name].rebalanceTx = rebalanceTx.transactionHash;
//      persistify(stateObject);
//      console.log(
//        `✔️ Successfully minted initial position. Please double-check the tx hash ${rebalanceTx.transactionHash}`
//      );
//    } else {
//      throw `❌❌ Failed minting initial position!`;
//    }
//  }
//
//  if (!stateObject[name].depositTx) {
//    // Deposit Want
//    console.log("\nDepositing in Jar...");
//    const t0Balance = await token0.balanceOf(deployer.address);
//    const t1Balance = await token1.balanceOf(deployer.address);
//    const depositTx = await executeTx(callAttempts, () =>
//      jar.deposit(t0Balance, t1Balance)
//    );
//    if (depositTx?.transactionHash) {
//      stateObject[name].depositTx = depositTx.transactionHash;
//      persistify(stateObject);
//      console.log(
//        `✔️ Successfully deposited want in Jar. Please double-check the tx hash ${depositTx.transactionHash}`
//      );
//    } else {
//      throw `❌❌ Failed depositing want in Jar!`;
//    }
//  }
//
//  if (!stateObject[name].harvestTx) {
//    // Harvest
//    const ratioBefore = await jar.getRatio();
//    console.log(
//      `\nWaiting for ${timers.harvestV3 / 1000}s before harvesting...`
//    );
//    await sleep(timers.harvestV3);
//    const harvestTx = await executeTx(callAttempts, () => strategy.harvest());
//
//    await sleep(timers.tx);
//    const ratioAfter = await jar.getRatio();
//
//    if (ratioAfter.gt(ratioBefore)) {
//      console.log(`✔️ Harvest was successful`);
//      stateObject[name].harvestTx = harvestTx.transactionHash;
//      persistify(stateObject);
//    } else {
//      console.log(`❌❌ Harvest failed, ratio has not increased`);
//    }
//  }
//
//  // Script Report
//  const report = `
//     ${stateObject[name].name} - ${stateObject[name].harvestTx ? "Fully Tested" : "TEST FAILED!"
//    }
//     jar:\t${stateObject[name].jar}
//     want:\t${stateObject[name].want}
//     strategy:\t${stateObject[name].strategy}
//     ----------------------------
//     `;
//  console.log(report);
//};


export const deployMiniChef = async() => {
  const minichefContract = "src/optimism/minichefv2.sol:MiniChefV2";
  const pickleAddress = "0x0c5b4c92c948691EEBf185C17eeB9c230DC019E9";
  const minichefAddress = await flatDeployAndVerifyContract(minichefContract, [pickleAddress], false);
  console.log(`MiniChefV2 Successfully deployed at ${minichefAddress}`);
}

export const deployRewarder = async() => {
  const rewarderContract = "src/optimism/PickleRewarder.sol:PickleRewarder";
  const opTokenAddress = "0x4200000000000000000000000000000000000042";
  const rewardPerSecond = 0;
  const minichefAddress = "0x849C283375A156A6632E8eE928308Fcb61306b7B";
  const rewarderAddress = await flatDeployAndVerifyContract(rewarderContract, [opTokenAddress, rewardPerSecond, minichefAddress], false);
  console.log(`Rewarder Successfully deployed at ${rewarderAddress}`);
  
}
