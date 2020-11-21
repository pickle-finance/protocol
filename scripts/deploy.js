const { ethers } = require("ethers");
const chalk = require("chalk");

const { ABIS, BYTECODE, KEYS } = require("./constants");
const { deployContract, provider } = require("./common");

const deployer = new ethers.Wallet(
  process.env.DEPLOYER_PRIVATE_KEY ||
    "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d",
  provider
);

const pickle_token = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const weth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";

const governance = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const devfund = "0x2fee17F575fa65C06F10eA2e63DBBc50730F145D";
const treasury = "0x066419EaEf5DE53cc5da0d8702b990c5bc7D1AB3";
const controller_v4 = "0x6847259b2B3A4c17e7c43C54409810aF48bA5210";

const strategist = "0x907D9B32654B8D43e8737E0291Ad9bfcce01DAD6";
const timelock_12 = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";

// Existing pickle jars
const pjar_scrv = "0x68d14d66B2B0d6E157c06Dc8Fefa3D8ba0e66a89";
const pjar_rencrv = "0x2E35392F4c36EBa7eCAFE4de34199b2373Af22ec";
const pjar_3crv = "0x1BB74b5DdC1f4fC91D6f9E7906cf68bc93538e33";
const pjar_ethdai_lp = "0xCffA068F1E44D98D3753966eBd58D4CFe3BB5162";
const pjar_ethusdc_lp = "0x53Bf2E62fA20e2b4522f05de3597890Ec1b352C6";
const pjar_ethusdt_lp = "0x09FC573c502037B149ba87782ACC81cF093EC6ef";
const pjar_ethwbtc_lp = "0xc80090AA05374d336875907372EE4ee636CBC562";
const pjar_dai = "0x6949Bb624E8e8A90F87cD2058139fcd77D2F3F87";

// Temporary governance
const tempGov = deployer.address;
const tempTimelock = deployer.address;

const main = async () => {
  if (!process.env.SOLC_FLAGS) {
    console.log(chalk.redBright(`SOLC_FLAGS not present, aborting...`));
    process.exit(1);
  }

  console.log(chalk.redBright(`DEPLOYER: ${deployer.address}`));
  console.log(chalk.redBright(`PROVIDER_URL: ${provider.connection.url}`));

  const tx = await deployContract({
    name: "StrategyCmpdDaiV3",
    abi: ABIS.Pickle.Strategies.StrategyCmpdDaiV3,
    bytecode: BYTECODE.Pickle.Strategies.StrategyCmpdDaiV3,
    deployer,
    wallet: deployer,
    args: [governance, strategist, controller_v4, timelock_12],
  });
};

main();
