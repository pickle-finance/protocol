const fetch = require("node-fetch");
const chalk = require("chalk");
const deployed = require("./deployed.json");
const solcInput = require("../solc-input.json");

const API_KEY = process.env.ETHERSCAN_API_KEY;
const COMPILER_VERSION =
  process.env.COMPILER_VERSION || "v0.6.7+commit.b8d736ae";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const waitForVerificationResults = async (guid) => {
  const req = {
    apikey: API_KEY,
    guid: guid,
    module: "contract",
    action: "checkverifystatus",
  };
  const params = new URLSearchParams({ ...req });
  const urlWithQuery = new URL("", "https://api.etherscan.io/api");
  urlWithQuery.search = params.toString();

  const response = await fetch(urlWithQuery);

  if (!response.ok) {
    const message = `The HTTP server response is not ok. Status code: ${response.status} Response text: ${responseText}`;
    console.log(chalk.redBright(message));
  }

  const responseText = await response.text();

  if (responseText.includes("Pending")) {
    await sleep(15000);
    await waitForVerificationResults(guid);
  }

  if (responseText.includes("Fail")) {
    console.log(chalk.redBright("Failed to verify"));
  }

  if (responseText.includes("Pass")) {
    console.log(chalk.greenBright("Successfully verified"));
  }
};

const verify = async (key) => {
  const { contract, address, args } = deployed[key];

  console.log(chalk.yellow(`Verifying ${key} at ${address}`));

  const req = {
    apikey: API_KEY, //A valid API-Key is required
    module: "contract", //Do not change
    action: "verifysourcecode", //Do not change
    contractaddress: address, //Contract Address starts with 0x...
    sourceCode: JSON.stringify(solcInput), //Contract Source Code (Flattened if necessary)
    codeformat: "solidity-standard-json-input", //solidity-single-file (default) or solidity-standard-json-input (for std-input-json-format support
    contractname: contract, //ContractName (if codeformat=solidity-standard-json-input, then enter contractname as ex: erc20.sol:erc20)
    compilerversion: COMPILER_VERSION, // see https://etherscan.io/solcversions for list of support versions
    constructorArguements: args.slice(2), // Remove 0x
  };

  const params = new URLSearchParams({ ...req });

  const requestDetails = {
    method: "post",
    body: params,
  };

  const response = await fetch("https://api.etherscan.io/api", requestDetails);

  const respJson = await response.json();

  if (respJson.status === "1") {
    console.log(
      chalk.yellowBright(
        `${key} successfully submitted, awaiting verification results...`
      )
    );

    const guid = respJson.result;

    await waitForVerificationResults(guid);
  } else {
    console.log(chalk.redBright(`Failed to verify ${key}`));
    console.log(JSON.stringify(respJson, null, 4));
  }
};

const main = async () => {
  if (!API_KEY) {
    console.log(
      chalk.redBright(`Missing ETHERSCAN_API_KEY environment variable`)
    );
  }

  if (!process.env.COMPILER_VERSION) {
    console.log(
      chalk.redBright(
        `No COMPILER_VERSION specified, defaulting to: ${COMPILER_VERSION}. See https://etherscan.io/solcversions for more versions.`
      )
    );
  }

  const contracts = Object.keys(deployed);

  for (const contract of contracts) {
    await verify(contract);
  }
};

main();
