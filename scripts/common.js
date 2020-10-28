const ethers = require("ethers");
const ora = require("ora");
const inquirer = require("inquirer");
const chalk = require("chalk");
const fs = require("fs");
const path = require("path");

const { ADDRESSES, ABIS } = require("./constants");

const DEFAULT_PROVIDER = "http://localhost:8545";
const DEFAULT_MNEMONIC =
  "myth like bonus scare over problem client lizard pioneer submit female collect";

const provider = new ethers.providers.JsonRpcProvider(
  process.env.PROVIDER_URL || DEFAULT_PROVIDER
);

const wallets = Array(10)
  .fill(0)
  .map((_, i) =>
    ethers.Wallet.fromMnemonic(
      process.env.MNEMONIC || DEFAULT_MNEMONIC,
      `m/44'/60'/0'/0/${i}`
    ).connect(provider)
  );

const [user, governance, strategist, rewards] = wallets;

const swapEthFor = async (ethAmountWei, toToken, user = wallets[0]) => {
  const UniswapV2Router = new ethers.Contract(
    ADDRESSES.UniswapV2.Router2,
    ABIS.UniswapV2.Router2,
    user
  );

  const now = parseInt(new Date().getTime() / 1000);

  const tx = await UniswapV2Router.swapExactETHForTokens(
    0,
    [ADDRESSES.ERC20.WETH, toToken],
    user.address,
    now + 420,
    {
      value: ethAmountWei,
      gasLimit: 900000,
    }
  );

  const txRecp = await tx.wait();

  return txRecp;
};

const getERC20 = (address, user = wallets[0]) => {
  return new ethers.Contract(address, ABIS.ERC20, user);
};

const getContract = (address, abi) => {
  return new ethers.Contract(address, abi);
};

const deployContract = async ({
  name,
  abi,
  bytecode,
  args = [],
  deployer = wallets[0],
  user = wallets[0],
}) => {
  const factory = new ethers.ContractFactory(abi, bytecode, deployer);

  const constructor = JSON.parse(abi).filter(
    (x) => x.type === "constructor"
  )[0];

  if (constructor) {
    const inputs = constructor.inputs.map((x) => x.name);
    if (inputs.length !== args.length) {
      console.log(
        chalk.red(
          `Invalid number of parameters for ${name}. Expected ${inputs.length}, got ${args.length}`
        )
      );
      process.exit(1);
    }
    const prettyArgs = Array(inputs.length)
      .fill(0)
      .map((_, i) => i)
      .reduce((acc, x) => {
        return { ...acc, [inputs[x]]: args[x] };
      }, {});

    console.log(
      chalk.yellow(`Deploying ${name} with the following parameters:`)
    );
    console.log(chalk.blue(JSON.stringify(prettyArgs, null, 4)));
  } else {
    console.log(chalk.yellow(`Deploying ${name} (no parameters)`));
  }

  const confirmationName = "confirmDeploy";
  const responses = await inquirer.prompt([
    {
      type: "confirm",
      name: confirmationName,
      message: chalk.yellow("Continue?"),
    },
  ]);

  if (responses[confirmationName]) {
    const spinner = ora(`Deploying ${name}`).start();

    const gasPrice = await deployer.provider.getGasPrice();
    const fastGasPrice = gasPrice
      .mul(ethers.BigNumber.from(125))
      .div(ethers.BigNumber.from(100));
    const contract = await factory.deploy(...args, {
      gasLimit: 12000000,
      gasPrice: fastGasPrice,
    });
    await contract.deployed();

    spinner.succeed(`Deployed ${name} to ${contract.address}`);

    const deployedOutput = path.resolve(__dirname, `deployed.json`);
    let deployedContent = {};
    if (fs.existsSync(deployedOutput)) {
      deployedContent = JSON.parse(fs.readFileSync(deployedOutput, "utf-8"));
    }
    fs.writeFileSync(
      deployedOutput,
      JSON.stringify(
        {
          ...deployedContent,
          [name]: contract.address,
        },
        null,
        4
      )
    );

    return new ethers.Contract(contract.address, abi, user);
  }

  process.exit(0);
};

module.exports = {
  wallets,
  provider,
  accounts: {
    user,
    governance,
    strategist,
    rewards,
  },
  swapEthFor,
  getERC20,
  deployContract,
  getContract,
};
