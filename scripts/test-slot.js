
const { ethers, network } = require("hardhat");
require("@nomiclabs/hardhat-waffle");
const shell = require('shelljs');

console.log("network: ",network);

const assetAddr = "0x3dAF1C6268362214eBB064647555438c6f365F96";
const walletAddr = "0xc9a51fB9057380494262fd291aED74317332C0a2";
const slot = shell.exec(`slot20 balanceOf ${assetAddr} ${walletAddr}`);
console.log('slot: ',slot);