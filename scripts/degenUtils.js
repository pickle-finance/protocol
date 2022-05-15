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

module.exports = { sleep, fastVerifyContracts, slowVerifyContracts }