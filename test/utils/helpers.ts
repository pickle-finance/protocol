const hre = require("hardhat");
const { ethers, network } = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";
import { 
   Signer 
} from "ethers";

// Return environment variable value if it exists else return empty string
//export function getEnvVar(varName: string) : string {
//   let value: string = process.env[varName] === undefined ? "" : process.env[varName];
//   return value;
//}

export async function increaseTime(sec: number) {
  // if (sec < 60) console.log(`⌛ Advancing ${sec} secs`);
  // else if (sec < 3600) console.log(`⌛ Advancing ${Number(sec / 60).toFixed(0)} mins`);
  // else if (sec < 60 * 60 * 24) console.log(`⌛ Advancing ${Number(sec / 3600).toFixed(0)} hours`);
  // else if (sec < 60 * 60 * 24 * 31) console.log(`⌛ Advancing ${Number(sec / 3600 / 24).toFixed(0)} days`);

  await hre.network.provider.send("evm_increaseTime", [sec]);
  await hre.network.provider.send("evm_mine");
}

export async function increaseBlock(block: number) {
  //console.log(`⌛ Advancing ${block} blocks`);
  for (let i = 1; i <= block; i++) {
    await hre.network.provider.send("evm_mine");
  }
}

export async function fastForwardAWeek() {
  let i = 0;
  do {
    await increaseTime(60 * 60 * 24);
    await increaseBlock(60 * 60);
    i++;
  } while (i < 8);
}

/*
function toWei(amount: string, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(decimal));
};

function fromWei(amount) => {
  return amount.div(1000000000000000000).toString();
};
*/

export function toGwei(amount: BigNumber) : string {
  return amount.div(1000000000).toString();
};

export async function overwriteTokenAmount(assetAddr: string, walletAddr: string, amount: string, slot: number = 0) {
  const index = ethers.utils.solidityKeccak256(["uint256", "uint256"], [walletAddr, slot]);
  const BN = ethers.BigNumber.from(amount)._hex.toString();
  const number = ethers.utils.hexZeroPad(BN, 32);

  await ethers.provider.send("hardhat_setStorageAt", [assetAddr, index, number]);
  await hre.network.provider.send("evm_mine");
}

export async function returnSigner(address: string) : Promise<Signer> {
  await network.provider.send('hardhat_impersonateAccount', [address]);
  return ethers.provider.getSigner(address)
}

export function findSlot (address: string) : number {
  let slot;
  switch (address) {
    case "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7": slot = 3; break; //WAVAX
    case "0x8729438eb15e2c8b576fcc6aecda6a148776c0f5": slot = 1; break; //QI
    case "0xdc42728b0ea910349ed3c6e1c9dc06b5fb591f98": slot = 2; break; //FRAX
    case "0x1c20e891bab6b1727d14da358fae2984ed9b59eb": slot = 14; break; //TUSD
    case "0xB91124eCEF333f17354ADD2A8b944C76979fE3EC": slot = 51; break; //s4D
    case "0x60781C2586D68229fde47564546784ab3fACA982": slot = 1; break; //PNG
    default: slot = 0; break;
  }
  return slot;
}

export function returnController(controller: string) : string {
  let address;
  switch (controller) {
    case "main":      address = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85"; break;
    case "backup":    address = "0xACc69DEeF119AB5bBf14e6Aaf0536eAFB3D6e046"; break;
    case "aave":      address = "0x425A863762BBf24A986d8EaE2A367cb514591C6F"; break;
    case "bankerJoe": address = "0xFb7102506B4815a24e3cE3eAA6B834BE7a5f2807"; break;
    default: address = ""; break;
  }
  return address
}
