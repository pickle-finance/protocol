import { hre } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
import { ethers, network } from "hardhat";
import { Signer } from "ethers";

export const snowballAddr: string = "0xC38f41A296A4493Ff429F1238e030924A1542e50";
export const treasuryAddr: string = "0x028933a66dd0ccc239a3d5c2243b2d96672f11f5";
export const devAddr:      string = "0x0aa5cb6f365259524f7ece8e09cce9a7b394077a";
export const MAX_UINT256: BigNumber = ethers.constants.MaxUint256;

export async function setupSigners() {
  const timelockAddr:   string = "0xc9a51fb9057380494262fd291aed74317332c0a2";
  const governanceAddr: string = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const strategistAddr: string = "0xc9a51fb9057380494262fd291aed74317332c0a2";

  await network.provider.send('hardhat_impersonateAccount', [timelockAddr]);
  await network.provider.send('hardhat_impersonateAccount', [strategistAddr]);
  await network.provider.send('hardhat_impersonateAccount', [governanceAddr]);

  let timelockSigner:   Signer = ethers.provider.getSigner(timelockAddr);
  let strategistSigner: Signer = ethers.provider.getSigner(strategistAddr);
  let governanceSigner: Signer = ethers.provider.getSigner(governanceAddr);

  let balance: string = "0x10000000000000000000000";
  await network.provider.send("hardhat_setBalance", [governanceSigner._address, balance,]);
  await network.provider.send("hardhat_setBalance", [timelockSigner._address,   balance,]);
  await network.provider.send("hardhat_setBalance", [strategistSigner._address, balance,]);

  return [timelockSigner,strategistSigner,governanceSigner];
};

/*
module.exports = {
  setupSigners,
  snowballAddr,
  treasuryAddr,
  devAddr,
  MAX_UINT256
};
*/
