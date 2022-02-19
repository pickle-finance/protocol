const {BigNumber} = require("ethers");
const {parseEther} = require("ethers/lib/utils");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const doneJson = require("../deployments/deployment-object.json");

// Script configs
const sleepToggle = true;
const callAttempts = 3;
const waitBeforeReplace = 60000; // time to wait for tx to confirm before replacing
const waitBeforeHarvest = 60000; // wait for rewards to accrue
const waitBeforeTx = 10000; // wait for the provider to update chain state (signer nonces, txns status ...etc)

// References
const allReports = [];
const done = JSON.parse(JSON.stringify(doneJson));

// Addresses & Contracts [Fantom]
const governance = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";
const strategist = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";
const controller = "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6";//"0xB1698A97b497c998b2B2291bb5C48D1d6075836a";
const timelock = "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB";

const contracts = [
  // "src/tmp/strategy-beethovenx-ftm-beets.sol:StrategyBeethovenFtmBeetsLp",
  // "src/tmp/strategy-beethovenx-ftm-btc-eth.sol:StrategyBeethovenFtmBtcEthLp",
  // "src/tmp/strategy-beethovenx-lqdr-ftm.sol:StrategyBeethovenLqdrFtmLp",
  // "src/tmp/strategy-beethovenx-wftm-matic-sol-avax-luna-bnb.sol:StrategyBeethovenWftmMaticSolAvaxLunaBnbLp",
  // "src/tmp/strategy-beethovenx-wftm-usdc.sol:StrategyBeethovenWftmUsdcLp",
  // "src/tmp/strategy-lqdr-sushi-wftm.sol:StrategyLqdrSushiWftm",
  // "src/tmp/strategy-beethovenx-usdc-ftm-btc-eth.sol:StrategyBeethovenUsdcFtmBtcEthLp",
  "src/tmp/strategy-beethovenx-usdc-dai-mai.sol:StrategyBeethovenUsdcDaiMaiLp", // pending harvest
];

const testedStratsAddresses = [
  // "0xb64f09dFE30Ba3A65be15498B3f32aE3068bdaEb",
];
const testedStratsContracts = [
  // "src/tmp/strategy-beethovenx-usdc-dai-mai.sol:StrategyBeethovenUsdcDaiMaiLp",
];

// Functions
const sleep = async (ms, active = true) => {
  if (active) {
    console.log(`Sleeping for ${ms / 1000}s...`);
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
};

const verifyStrats = async () => {
  console.log(`Verifying contracts...`);
  for (let i = 0; i < testedStratsAddresses.length; i++) {
    try {
      await hre.run("verify:verify", {
        contract: testedStratsContracts[i],
        address: testedStratsAddresses[i],
        constructorArguments: [governance, strategist, controller, timelock],
      });
    } catch (e) {
      console.error(e);
    }
  }
};

const deployAndTest = async () => {
  const executeTx = async (tries, fn, deployTx = false, tx = undefined) => {
    await sleep(waitBeforeTx, sleepToggle);

    let timeout, receiptPromise, txn;

    const timeoutPromise = new Promise((resolve, _reject) => {
      timeout = setTimeout(() => {
        resolve("timeout");
      }, waitBeforeReplace);
    });

    if (tx) {
      console.log("Transaction took too long. Retrying...");
      const signer = await hre.ethers.getSigner();

      // extract unnecessary props from previous tx
      let {
        hash,
        gasPrice,
        maxFeePerGas,
        maxPriorityFeePerGas,
        blockHash,
        blockNumber,
        transactionIndex,
        confirmations,
        creates,
        wait,
        r,
        s,
        v,
        ...reTx
      } = tx;

      // increase gas price by 11% (p.s: sometimes tx will arrive here with gasPrice set to undefined)
      reTx.gasPrice = gasPrice ? gasPrice.mul(ethers.BigNumber.from(111)).div(ethers.BigNumber.from(100)) : undefined;
      try {
        txn = await signer.sendTransaction(reTx);
      } catch (error) {
        // these are the most common issues deployment faces
        // feel free to add new ones

        // 1) previous tx confirmed before the replace
        if (error.code === "NONCE_EXPIRED") {
          console.log(`${error.code}! Retrying...`);
          txn = tx;
        } else {
          console.log("New error encountered! Please investigate!");
          console.error(error);
          return;
        }
      }
    } else {
      try {
        txn = await fn();
      } catch (error) {
        // these are the most common issues deployment faces
        // feel free to add new ones

        // 1) provider didn't update the signer nonce yet
        if (error.code === "NONCE_EXPIRED") {
          return await executeTx(tries, fn, deployTx);
        }

        // 2) usually with a failing harvest (not enough rewards accrued)
        else if (error.code === "UNPREDICTABLE_GAS_LIMIT") {
          console.error(`Tx failed with code: ${error.code}`);
          if (tries > 0) {
            console.log("Retrying...");
            return await executeTx(tries - 1, fn, deployTx, txn);
          }
        } else {
          console.log("New error encountered! Please investigate!");
          console.log(error);
          return;
        }
      }
    }

    try {
      if (deployTx) {
        console.log(
          `Waiting for tx ${
            txn.deployTransaction.hash
          } with gas price: ${txn.deployTransaction.gasPrice.toString()} to confirm...`
        );
        receiptPromise = txn.deployTransaction.wait();
      } else {
        console.log(`Waiting for tx ${txn.hash} with gas price: ${txn.gasPrice.toString()} to confirm...`);
        receiptPromise = txn.wait();
      }
      const response = await Promise.race([receiptPromise, timeoutPromise]);
      if (timeout) {
        clearTimeout(timeout);
      }
      if (response === "timeout" && tries > 0) {
        return await executeTx(tries - 1, fn, deployTx, txn);
      } else if (response === "timeout") {
        return;
      }
      response.address = txn.address; // attach jar/strategy address to response
      return response;
    } catch (err) {
      console.log("Transaction reverted!");
      console.error(err);
      return;
    }
  };

  const deployer = await hre.ethers.getSigner();
  console.log(`Deployer: ${deployer.address}`);

  for (const contract of contracts) {
    const StrategyFactory = await ethers.getContractFactory(contract);
    const PickleJarFactory = await ethers.getContractFactory("src/pickle-jar.sol:PickleJar");
    const Controller = await ethers.getContractAt("src/controller-v4.sol:ControllerV4", controller);
    const name = contract.substring(contract.lastIndexOf(":") + 1);

    let strategy, jar;

    // Retrieve deployed contracts
    if (done[name]) {
      if (done[name].strategy) {
        strategy = await ethers.getContractAt(contract, done[name].strategy);
      }
      if (done[name].jar) {
        jar = await ethers.getContractAt("src/pickle-jar.sol:PickleJar", done[name].jar);
      }
    } else {
      done[name] = {name: name};
    }

    try {
      if (!strategy) {
        // Deploy Strategy contract
        console.log(`Deploying ${name}...`);

        const strategyTx = await executeTx(
          callAttempts,
          () => StrategyFactory.deploy(governance, strategist, controller, timelock),
          true
        );
        done[name].strategy = strategyTx.address;
        strategy = await ethers.getContractAt(contract, done[name].strategy);
      }

      if (strategy && !jar) {
        console.log(`✔️ Strategy deployed at: ${strategy.address}`);

        // Get Want
        await sleep(waitBeforeTx);
        done[name].want = await strategy.want();

        // Deploy PickleJar contract
        const jarTx = await executeTx(
          callAttempts,
          () => PickleJarFactory.deploy(done[name].want, governance, timelock, controller),
          true
        );
        done[name].jar = jarTx.address;
        jar = await ethers.getContractAt("src/pickle-jar.sol:PickleJar", done[name].jar);
      }

      if (jar && !done[name].wantApproveTx) {
        console.log(`✔️ PickleJar deployed at: ${jar.address}`);

        // Log Want
        console.log(`Want address is: ${done[name].want}`);
        console.log(`Approving want token for deposit...`);
        const wantContract = await ethers.getContractAt("src/lib/erc20.sol:ERC20", done[name].want);

        // Approve Want
        const approveTx = await executeTx(callAttempts, () =>
          wantContract.approve(jar.address, ethers.constants.MaxUint256)
        );
        done[name].wantApproveTx = approveTx?.transactionHash;
      }

      if (done[name].wantApproveTx && !done[name].stratApproveTx) {
        console.log(`✔️ Successfully approved Jar to spend want`);
        console.log(`Setting all the necessary stuff in controller...`);

        // Approve Strategy
        const approveStratTx = await executeTx(callAttempts, () =>
          Controller.approveStrategy(done[name].want, strategy.address)
        );
        done[name].stratApproveTx = approveStratTx?.transactionHash;
      }

      if (done[name].stratApproveTx && !done[name].jarSetTx) {
        console.log(`Strategy Approved!`);

        // Set Jar
        const setJarTx = await executeTx(callAttempts, () => Controller.setJar(done[name].want, jar.address));
        done[name].jarSetTx = setJarTx?.transactionHash;
      }

      if (done[name].jarSetTx && !done[name].stratSetTx) {
        console.log(`Jar Set!`);

        // Set Strategy
        const setStratTx = await executeTx(callAttempts, () =>
          Controller.setStrategy(done[name].want, strategy.address)
        );
        done[name].stratSetTx = setStratTx?.transactionHash;
      }

      if (done[name].stratSetTx && !done[name].depositTx) {
        console.log(`Strategy Set!`);
        console.log(`✔️ Controller params all set!`);

        // Deposit Want
        console.log(`Depositing in Jar...`);
        const depositTx = await executeTx(callAttempts, () => jar.depositAll());
        done[name].depositTx = depositTx?.transactionHash;
      }

      if (done[name].depositTx && !done[name].earnTx) {
        console.log(`✔️ Successfully deposited want in Jar`);

        // Call Earn
        console.log(`Calling earn...`);
        const earnTx = await executeTx(callAttempts, () => jar.earn());
        done[name].earnTx = earnTx?.transactionHash;
      }

      if (done[name].earnTx && !done[name].harvestTx) {
        console.log(`✔️ Successfully called earn`);

        // Call Harvest
        console.log(`Waiting for ${waitBeforeHarvest / 1000}s before harvesting...`);
        await sleep(waitBeforeHarvest);
        const harvestTx = await executeTx(callAttempts, () => strategy.harvest());

        await sleep(waitBeforeTx);
        const ratio = await jar.getRatio();

        if (ratio.gt(BigNumber.from(parseEther("1")))) {
          console.log(`✔️ Harvest was successful, ending ratio of ${ratio.toString()}`);
          testedStratsAddresses.push(strategy.address);
          testedStratsContracts.push(contract);
          done[name].harvestTx = harvestTx?.transactionHash;
        } else {
          console.log(`❌ Harvest failed, ending ratio of ${ratio.toString()}`);
        }
      }
    } catch (e) {
      console.log(`Oops something went wrong...`);
      console.error(e);
    }

    // Script Report
    const report = `
    ${done[name].name} - ${done[name].harvestTx ? "Fully Tested" : "DEPLOYMENT FAILED!"}
    jar:\t${done[name].jar}
    want:\t${done[name].want}
    strategy:\t${done[name].strategy}
    ----------------------------
    `;

    allReports.push(report);
  }

  console.log(
    `
    -----------------------------
    -   Here's the full report  -
    -----------------------------
    ${allReports.join("\n")}
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    `
  );

  const doneStringified = JSON.stringify(done, null, 4);
  fs.writeFileSync("deployments/deployment-object.json", doneStringified, (err) => {
    if (err) console.log(err);
  });
};

const main = async () => {
  await deployAndTest();
  await verifyStrats();
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
