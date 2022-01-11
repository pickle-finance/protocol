const hre = require("hardhat")
const { ethers } = require("hardhat")
import {
    Contract,
    Signer
} from "ethers";

import { log } from "./../utils/log";
import { returnSigner } from "./../utils/helpers";

const BLACKHOLE = "0x0000000000000000000000000000000000000000"

export async function setupMockSnowGlobe(
    contract_name: string, snowglobe_addr: string, asset_addr: string,
    Controller: Contract, timelockSigner: Signer,
    governanceSigner: Signer) {

    let globeABI = (await ethers.getContractFactory(contract_name)).interface;
    let SnowGlobe: Contract

    if (snowglobe_addr == "") {
        snowglobe_addr = await Controller.globes(asset_addr);

        log(`controller_addr: ${Controller.address}`);
        log(`snowglobe_addr: ${snowglobe_addr}`);

        if (snowglobe_addr != BLACKHOLE) {
            SnowGlobe = new ethers.Contract(snowglobe_addr, globeABI, governanceSigner);
            log(`connected to snowglobe at ${SnowGlobe.address}`);

        } else {
            const globeFactory = await ethers.getContractFactory(contract_name);
            const governance_addr = await governanceSigner.getAddress()
            const controller_addr = Controller.address
            const timelock_addr = await timelockSigner.getAddress()
            SnowGlobe = await globeFactory.deploy(
                asset_addr,
                governance_addr,
                timelock_addr,
                controller_addr
            );
            log(`deployed new snowglobe at ${SnowGlobe.address}`);
            const setGlobe = await Controller.setGlobe(asset_addr, SnowGlobe.address);
            const tx_setGlobe = await setGlobe.wait(1);
            if (!tx_setGlobe.status) {
                console.error(`Error setting the globe for: ${contract_name}`);
                return SnowGlobe;
            }
            log(`Set Globe in the Controller for: ${contract_name}`);
            snowglobe_addr = SnowGlobe.address;
        }
    } else {
        SnowGlobe = new ethers.Contract(snowglobe_addr, globeABI, governanceSigner);
        log(`connected to snowglobe at ${SnowGlobe.address}`);
    }

    return SnowGlobe;
}
