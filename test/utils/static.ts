const hre = "hardhat";
const { ethers, network } = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";
import { Signer } from "ethers";

export const snowball_addr: string = "0xC38f41A296A4493Ff429F1238e030924A1542e50";
export const treasury_addr: string = "0x028933a66dd0ccc239a3d5c2243b2d96672f11f5";
export const dev_addr: string = "0x0aa5cb6f365259524f7ece8e09cce9a7b394077a";
export const MAX_UINT256: BigNumber = ethers.constants.MaxUint256;
export const WAVAX_ADDR = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";

/***
 * NOTE: Single Staking expects the timelock signer to have the address of the strategist.
 */
export async function setupSigners(timelockIsStrategist: boolean = false) {
    const governanceAddr: string = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
    const strategistAddr: string = "0xc9a51fb9057380494262fd291aed74317332c0a2";
    const timelockAddr: string = timelockIsStrategist ? "0xc9a51fb9057380494262fd291aed74317332c0a2" : "0x3d88b8022142ea2693ba43BA349F89256392d59b";

    await network.provider.send('hardhat_impersonateAccount', [timelockAddr]);
    await network.provider.send('hardhat_impersonateAccount', [strategistAddr]);
    await network.provider.send('hardhat_impersonateAccount', [governanceAddr]);

    let timelockSigner: Signer = ethers.provider.getSigner(timelockAddr);
    let strategistSigner: Signer = ethers.provider.getSigner(strategistAddr);
    let governanceSigner: Signer = ethers.provider.getSigner(governanceAddr);

    let governance_addr = await governanceSigner.getAddress()
    let timelock_addr = await timelockSigner.getAddress()
    let strategist_addr = await strategistSigner.getAddress()

    let balance: string = "0x10000000000000000000000";
    await network.provider.send("hardhat_setBalance", [governance_addr, balance,]);
    await network.provider.send("hardhat_setBalance", [timelock_addr, balance,]);
    await network.provider.send("hardhat_setBalance", [strategist_addr, balance,]);

    return [timelockSigner, strategistSigner, governanceSigner];
};
