const { ethers } = require("hardhat");
require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

async function main() {
  const platform = "Kyber";
  const controller_name = platform+"ControllerV4";
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const governance_addr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const strategist_addr = "0x3d88b8022142ea2693ba43BA349F89256392d59b"; //setStrategy
  const timelock_addr = "0x3d88b8022142ea2693ba43BA349F89256392d59b"; //approveStratgey
  const devfund_addr = "0x0Aa5CB6F365259524F7Ece8e09ccE9A7B394077A";
  const treasury_addr = "0x028933a66DD0cCC239a3d5c2243b2d96672f11F5";

  const controllerFactory = await ethers.getContractFactory(controller_name);

  const Controller = await controllerFactory.deploy(governance_addr, strategist_addr, timelock_addr, devfund_addr, treasury_addr);
  console.log(`deployed ${controller_name} at : ${Controller.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
