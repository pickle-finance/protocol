const { ethers } = require("ethers");
const chalk = require("chalk");

const { ABIS, BYTECODE, KEYS } = require("./constants");
const { deployContract, provider } = require("./common");

const deployer = new ethers.Wallet(
  process.env.DEPLOYER_PRIVATE_KEY ||
    "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d",
  provider
);

// PickleJar
const PickleJar = new ethers.Contract(
  ethers.constants.AddressZero,
  ABIS.Pickle.PickleJar,
  deployer
);

const devfund = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const treasury = "0x066419EaEf5DE53cc5da0d8702b990c5bc7D1AB3";
const governance = devfund;

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
  console.log(chalk.redBright(`DEPLOYER: ${deployer.address}`));
  console.log(chalk.redBright(`PROVIDER_URL: ${provider.connection.url}`));

  const verifyCliCmds = [];

  // Deploy controller
  const controllerArgs = [tempGov, strategist, tempTimelock, devfund, treasury];
  const ControllerV4 = await deployContract({
    name: "ControllerV4",
    abi: ABIS.Pickle.ControllerV4,
    bytecode: BYTECODE.Pickle.ControllerV4,
    args: controllerArgs,
    deployer,
    user: deployer,
  });

  verifyCliCmds.push(
    `DAPP_ROOT=$(pwd) DAPP_JSON=out/dapp.sol.json ./scripts/verify.sh ${
      KEYS.Pickle.ControllerV4
    } ${ControllerV4.address} ${controllerArgs.join(" ")}`
  );

  const contGov = await ControllerV4.governance();
  const contStrat = await ControllerV4.strategist();
  const contDevFund = await ControllerV4.devfund();
  const contTreasury = await ControllerV4.treasury();
  const contTimelock = await ControllerV4.timelock();

  if (contStrat.toLowerCase() != strategist.toLowerCase()) {
    console.log(chalk.red(`Invalid strategist`));
    process.exit(1);
  }
  if (contDevFund.toLowerCase() != devfund.toLowerCase()) {
    console.log(chalk.red(`Invalid devfund`));
    process.exit(1);
  }
  if (contTreasury.toLowerCase() != treasury.toLowerCase()) {
    console.log(chalk.red(`Invalid treasury`));
    process.exit(1);
  }
  if (contGov.toLowerCase() != tempGov.toLowerCase()) {
    console.log(chalk.red(`Invalid gov`));
    process.exit(1);
  }
  if (contTimelock.toLowerCase() != tempTimelock.toLowerCase()) {
    console.log(chalk.red(`Invalid timelock`));
    process.exit(1);
  }

  // Deploy converters
  const converters = [
    ["CurveProxyLogic", KEYS.Pickle.ProxyLogic.Curve],
    ["UniswapV2ProxyLogic", KEYS.Pickle.ProxyLogic.UniswapV2],
  ];

  for (const [converterName, key] of converters) {
    const ProxyLogic = await deployContract({
      name: converterName,
      abi: ABIS.Pickle.ProxyLogic[converterName],
      bytecode: BYTECODE.Pickle.ProxyLogic[converterName],
      args: [],
      deployer,
      user: deployer,
    });
    const tx = await ControllerV4.approveJarConverter(ProxyLogic.address);
    await tx.wait();

    const approved = await ControllerV4.approvedJarConverters(
      ProxyLogic.address
    );

    if (!approved) {
      console.log(chalk.red(`Converter not approved`));
      process.exit(1);
    }

    verifyCliCmds.push(
      `DAPP_ROOT=$(pwd) DAPP_JSON=out/dapp.sol.json ./scripts/verify.sh ${key} ${ProxyLogic.address}`
    );
  }

  // Deploy strategies
  const strategies = [
    ["StrategyCmpdDaiV2", pjar_dai, KEYS.Pickle.Strategies.StrategyCmpdDaiV2],
    [
      "StrategyCurve3CRVv2",
      pjar_3crv,
      KEYS.Pickle.Strategies.StrategyCurve3CRVv2,
    ],
    [
      "StrategyCurveSCRVv3_2",
      pjar_scrv,
      KEYS.Pickle.Strategies.StrategyCurveSCRVv3_2,
    ],
    [
      "StrategyCurveRenCRVv2",
      pjar_rencrv,
      KEYS.Pickle.Strategies.StrategyCurveRenCRVv2,
    ],
    [
      "StrategyUniEthDaiLpV4",
      pjar_ethdai_lp,
      KEYS.Pickle.Strategies.StrategyUniEthDaiLpV4,
    ],
    [
      "StrategyUniEthUsdcLpV4",
      pjar_ethusdc_lp,
      KEYS.Pickle.Strategies.StrategyUniEthUsdcLpV4,
    ],
    [
      "StrategyUniEthUsdtLpV4",
      pjar_ethusdt_lp,
      KEYS.Pickle.Strategies.StrategyUniEthUsdtLpV4,
    ],
    [
      "StrategyUniEthWBtcLpV2",
      pjar_ethwbtc_lp,
      KEYS.Pickle.Strategies.StrategyUniEthWBtcLpV2,
    ],
  ];

  const controller = ControllerV4.address;
  for (const [stratName, jarAddress, key] of strategies) {
    const stratArgs = [governance, strategist, controller, timelock_12];
    const Strategy = await deployContract({
      name: stratName,
      abi: ABIS.Pickle.Strategies[stratName],
      bytecode: BYTECODE.Pickle.Strategies[stratName],
      args: stratArgs,
      deployer,
      user: deployer,
    });

    const want = await Strategy.want();
    const jarToken = await PickleJar.attach(jarAddress).token();

    if (jarToken.toLowerCase() !== want.toLowerCase()) {
      console.log(
        chalk.red(
          `Jar and Strategy expecting different tokens, want: ${want}, jarToken ${jarToken}`
        )
      );
    }

    const realStratName = await Strategy.getName();
    if (realStratName !== stratName) {
      console.log(
        chalk.red(
          `Jar and Strategy expecting different names, stratName: ${stratName}, realStratName ${realStratName}`
        )
      );
    }

    console.log(chalk.gray("setJar..."));
    let tx = await ControllerV4.setJar(want, jarAddress, {
      gasLimit: 1000000,
    });
    console.log(chalk.gray(`setJar tx: ${tx.hash}`));
    await tx.wait();

    console.log(chalk.gray("approvingStrategy..."));
    tx = await ControllerV4.approveStrategy(want, Strategy.address, {
      gasLimit: 1000000,
    });
    console.log(chalk.gray(`approvingStrategy tx: ${tx.hash}`));
    await tx.wait();

    console.log(chalk.gray("setStrategy..."));
    tx = await ControllerV4.setStrategy(want, Strategy.address, {
      gasLimit: 1000000,
    });
    console.log(chalk.gray(`setStrategy tx: ${tx.hash}`));
    await tx.wait();

    // Make sure jar is set
    const controllerJar = await ControllerV4.jars(want);
    if (controllerJar.toLowerCase() !== jarAddress.toLowerCase()) {
      console.log(
        chalk.red(`Invalid jar, expected: ${jarAddress}, got ${controllerJar}`)
      );
    }

    const controllerStrat = await ControllerV4.strategies(want);
    if (controllerStrat.toLowerCase() !== Strategy.address.toLowerCase()) {
      console.log(
        chalk.red(
          `Invalid strategy, expected: ${Strategy.address}, got ${controllerStrat}`
        )
      );
    }

    verifyCliCmds.push(
      `DAPP_ROOT=$(pwd) DAPP_JSON=out/dapp.sol.json ./scripts/verify.sh ${key} ${
        Strategy.address
      } ${stratArgs.join(" ")}`
    );
  }

  console.log(chalk.blue("Transferring governance on controller"));
  let tx = await ControllerV4.setGovernance(governance);
  console.log(chalk.grey(`Tx hash: ${tx.hash}`));
  await tx.wait();
  const controllerGov = await ControllerV4.governance();
  if (controllerGov.toLowerCase() !== governance.toLowerCase()) {
    console.log(chalk.red("Invalid governance!"));
  }

  console.log(chalk.blue("Transferring timelock on controller"));
  tx = await ControllerV4.setTimelock(timelock_12);
  console.log(chalk.grey(`Tx hash: ${tx.hash}`));
  await tx.wait();
  const controllerTimelock = await ControllerV4.timelock();
  if (controllerTimelock.toLowerCase() !== timelock_12.toLowerCase()) {
    console.log(chalk.red("Invalid timelock!"));
  }

  console.log(chalk.grey("--------- Verification ---------"));
  console.log(JSON.stringify(verifyCliCmds, null, 4));
};

main();
