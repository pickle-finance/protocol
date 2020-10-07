const { ethers } = require("ethers");
const chalk = require("chalk");

const { ABIS, BYTECODE } = require("./constants");
const { deployContract, provider } = require("./common");

const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY, provider);

const controller = "0x2ff3e6C2E054ABf45E21f790163970df82b0ea90";

const devfund = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const treasury = "0x066419EaEf5DE53cc5da0d8702b990c5bc7D1AB3";
const governance = devfund;

const strategist = "0x907D9B32654B8D43e8737E0291Ad9bfcce01DAD6";
const timelock_12 = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";

// Temporary governance
const tempGov = deployer.address;
const tempTimelock = deployer.address;

const main = async () => {
  console.log(chalk.redBright(`DEPLOYER: ${deployer.address}`));
  console.log(chalk.redBright(`PROVIDER_URL: ${provider.connection.url}`));

  const strategies = [
    ["StrategyCurve3CRVv1", "p3CRV"],
    ["StrategyCurveRenCRVv1", "pRenCrv"],
    ["StrategyUniEthWBtcLpV1", "pUNIWBTC"],
  ];

  for (const [stratName, jarName] of strategies) {
    const Strategy = await deployContract({
      name: stratName,
      abi: ABIS.Pickle.Strategies[stratName],
      bytecode: BYTECODE.Pickle.Strategies[stratName],
      args: [governance, strategist, controller, timelock_12],
      deployer,
      user: deployer,
    });
    await deployContract({
      name: jarName,
      abi: ABIS.Pickle.PickleJar,
      bytecode: BYTECODE.Pickle.PickleJar,
      args: [await Strategy.want(), governance, timelock_12, controller],
      deployer,
      user: deployer,
    });
  }
};

main();
