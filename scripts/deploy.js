const { ethers } = require("ethers");
const chalk = require("chalk");

const { ABIS, BYTECODE } = require("./constants");
const { deployContract, provider } = require("./common");

const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY, provider);

const scrv = "0xC25a3A3b969415c80451098fa907EC722572917F";
const uniEthDai = "0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11";
const uniEthUsdc = "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc";
const uniEthUsdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

const devfund = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const treasury = "0x066419EaEf5DE53cc5da0d8702b990c5bc7D1AB3";
const governance = devfund;

const strategist = "0x907D9B32654B8D43e8737E0291Ad9bfcce01DAD6";
const timelock_12 = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";

// Temporary governance
const tempGov = deployer.address;
const tempTimelock = deployer.address;

const main = async () => {
  const ControllerV3 = await deployContract({
    name: "ControllerV3",
    abi: ABIS.Pickle.ControllerV3,
    bytecode: BYTECODE.Pickle.ControllerV3,
    args: [tempGov, strategist, tempTimelock, devfund, treasury],
    deployer,
    user: deployer,
  });

  const contGov = await ControllerV3.governance();
  const contStrat = await ControllerV3.strategist();
  const contDevFund = await ControllerV3.devfund();
  const contTreasury = await ControllerV3.treasury();
  const contTimelock = await ControllerV3.timelock();

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

  const setJarApproveAndSetStrategy = async (jar, strat) => {
    const gasPrice = await deployer.provider.getGasPrice();
    const fastGasPrice = gasPrice
      .mul(ethers.BigNumber.from(125))
      .div(ethers.BigNumber.from(100));

    const want = await strat.want();

    console.log(chalk.gray("setJar..."));
    let tx = await ControllerV3.setJar(want, jar.address, {
      gasLimit: 1000000,
      gasPrice: fastGasPrice,
    });
    console.log(chalk.gray(`setJar tx: ${tx.hash}`));
    await tx.wait();

    console.log(chalk.gray("approvingStrategy..."));
    tx = await ControllerV3.approveStrategy(want, strat.address, {
      gasLimit: 1000000,
      gasPrice: fastGasPrice,
    });
    console.log(chalk.gray(`approvingStrategy tx: ${tx.hash}`));
    await tx.wait();

    console.log(chalk.gray("setStrategy..."));
    tx = await ControllerV3.setStrategy(want, strat.address, {
      gasLimit: 1000000,
      gasPrice: fastGasPrice,
    });
    console.log(chalk.gray(`setStrategy tx: ${tx.hash}`));
    await tx.wait();

    // Make sure jar is set
    const controllerJar = await ControllerV3.jars(want);
    if (controllerJar.toLowerCase() !== jar.address.toLowerCase()) {
      console.log(
        chalk.red(`Invalid jar, expected: ${jar.address}, got ${controllerJar}`)
      );
    }

    const controllerStrat = await ControllerV3.strategies(want);
    if (controllerStrat.toLowerCase() !== strat.address.toLowerCase()) {
      console.log(
        chalk.red(
          `Invalid strategy, expected: ${strat.address}, got ${controllerStrat}`
        )
      );
    }
  };

  const psCRV = await deployContract({
    name: "psCRV",
    abi: ABIS.Pickle.PickleJar,
    bytecode: BYTECODE.Pickle.PickleJar,
    args: [scrv, governance, timelock_12, ControllerV3.address],
    deployer,
    user: deployer,
  });
  const StrategyCurveSCRVv3 = await deployContract({
    name: "StrategyCurveSCRVv3",
    abi: ABIS.Pickle.Strategies.Curve.StrategyCurveSCRVv3,
    bytecode: BYTECODE.Pickle.Strategies.Curve.StrategyCurveSCRVv3,
    args: [governance, strategist, timelock_12, ControllerV3.address],
    deployer,
    user: deployer,
  });
  await setJarApproveAndSetStrategy(psCRV, StrategyCurveSCRVv3);

  const psUNIDAI = await deployContract({
    name: "psUNIDAI",
    abi: ABIS.Pickle.PickleJar,
    bytecode: BYTECODE.Pickle.PickleJar,
    args: [uniEthDai, governance, timelock_12, ControllerV3.address],
    deployer,
    user: deployer,
  });
  const StrategyUniEthDaiLpV3 = await deployContract({
    name: "StrategyUniEthDaiLpV3",
    abi: ABIS.Pickle.Strategies.UniswapV2.StrategyUniEthDaiLpV3,
    bytecode: BYTECODE.Pickle.Strategies.UniswapV2.StrategyUniEthDaiLpV3,
    args: [governance, strategist, ControllerV3.address, timelock_12],
    deployer,
    user: deployer,
  });
  await setJarApproveAndSetStrategy(psUNIDAI, StrategyUniEthDaiLpV3);

  const psUNIUSDC = await deployContract({
    name: "psUNIUSDC",
    abi: ABIS.Pickle.PickleJar,
    bytecode: BYTECODE.Pickle.PickleJar,
    args: [uniEthUsdc, governance, timelock_12, ControllerV3.address],
    deployer,
    user: deployer,
  });
  const StrategyUniEthUsdcLpV3 = await deployContract({
    name: "StrategyUniEthUsdcLpV3",
    abi: ABIS.Pickle.Strategies.UniswapV2.StrategyUniEthUsdcLpV3,
    bytecode: BYTECODE.Pickle.Strategies.UniswapV2.StrategyUniEthUsdcLpV3,
    args: [governance, strategist, ControllerV3.address, timelock_12],
    deployer,
    user: deployer,
  });
  await setJarApproveAndSetStrategy(psUNIUSDC, StrategyUniEthUsdcLpV3);

  const psUNIUSDT = await deployContract({
    name: "psUNIUSDT",
    abi: ABIS.Pickle.PickleJar,
    bytecode: BYTECODE.Pickle.PickleJar,
    args: [uniEthUsdt, governance, timelock_12, ControllerV3.address],
    deployer,
    user: deployer,
  });
  const StrategyUniEthUsdtLpV3 = await deployContract({
    name: "StrategyUniEthUsdtLpV3",
    abi: ABIS.Pickle.Strategies.UniswapV2.StrategyUniEthUsdtLpV3,
    bytecode: BYTECODE.Pickle.Strategies.UniswapV2.StrategyUniEthUsdtLpV3,
    args: [governance, strategist, ControllerV3.address, timelock_12],
    deployer,
    user: deployer,
  });
  await setJarApproveAndSetStrategy(psUNIUSDT, StrategyUniEthUsdtLpV3);

  console.log(chalk.blue("Transferring governance on controller"));
  let tx = await ControllerV3.setGovernance(governance);
  console.log(chalk.grey(`Tx hash: ${tx.hash}`));
  await tx.wait();
  const controllerGov = await ControllerV3.governance();
  if (controllerGov.toLowerCase() !== governance.toLowerCase()) {
    console.log(chalk.red("Invalid governance!"));
  }

  console.log(chalk.blue("Transferring timelock on controller"));
  tx = await ControllerV3.setTimelock(timelock_12);
  console.log(chalk.grey(`Tx hash: ${tx.hash}`));
  await tx.wait();
  const controllerTimelock = await ControllerV3.timelock();
  if (controllerTimelock.toLowerCase() !== timelock_12.toLowerCase()) {
    console.log(chalk.red("Invalid governance!"));
  }

  console.log(chalk.green("Deployed!"));
};

main();
