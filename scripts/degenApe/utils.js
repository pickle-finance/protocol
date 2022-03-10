const sleep = async (configs) => {
  if (configs.sleepToggle) {
    console.log("Sleeping...")
    return new Promise((resolve) => setTimeout(resolve, configs.sleepTime));
  }
};

// Use this for verification of 5 contracts or less
const fastVerifyContracts = async (strategies) => {
  // await exec("npx hardhat clean");
  console.log(`Verifying contracts...`);
  await Promise.all(strategies.map(async (strategy) => {
    try {
      await hre.run("verify:verify", {
        address: strategy,
        constructorArguments: [governance, strategist, controller, timelock],
      });
    } catch (e) {
      console.error(e);
    }
  }));
}

// Use this for verificationof 5 contracts or more
const slowVerifyContracts = async (strategies) => {
  for (strategy of strategies) {
    try {
      await hre.run("verify:verify", {
        address: strategy,
        constructorArguments: [governance, strategist, controller, timelock],
      });
    } catch (e) {
      console.error(e);
    }
  }
}

// const executeTx = async (configs, tx, fn, ...args) => {
//   await sleep(configs.sleepTime, configs.sleepToggle);
//   // if (!txRefs[tx]) { recall(executeTx, calls, tx, fn, ...args) }
//   try {
//     if (!txRefs[tx]) {
//       txRefs[tx] = await fn(...args)
//       if (tx === 'strategy') {
//         await txRefs[tx].deployTransaction.wait();
//       }
//       else if (tx === 'jar') {
//         const jarTx = await txRefs[tx].deployTransaction.wait();
//         txRefs['jarStartBlock'] = jarTx.blockNumber;
//       } else {
//         await txRefs[tx].wait();
//       }
//     }
//   } catch (e) {
//     console.error(e);
//     if (calls > 0) {
//       console.log(`Trying again. ${calls} more attempts left.`);
//       await executeTx(configs.calls - 1, tx, fn, ...args);
//     } else {
//       console.log('Looks like something is broken!');
//       return;
//     }
//   }
//   await sleep(configs.sleepTime, configs.sleepToggle);
// }

module.exports = { sleep, fastVerifyContracts, slowVerifyContracts }