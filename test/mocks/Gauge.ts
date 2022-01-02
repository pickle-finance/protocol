const hre = require("hardhat")
const { ethers } = require("hardhat")
import { 
   Contract, 
   ContractFactory, 
   Signer 
} from "ethers";

import { getContractName, addGauge } from "./../utils/helpers";

import { log } from "./../utils/log";


export async function setupMockGauge(name: string, gauge_addr: string, lp_token_addr: string, SnowGlobe: Contract, governanceSigner: Signer, gauge_proxy_addr: string) {
    let Gauge: Contract;
    if (gauge_addr == "") {
        const gauge_factory: ContractFactory = await ethers.getContractFactory("GaugeV2");
        Gauge = await gauge_factory.deploy(lp_token_addr, await governanceSigner.getAddress());
        // Setup new gauge with GaugeProxy
        addGauge(name, SnowGlobe, governanceSigner, gauge_proxy_addr)
    } else {
        Gauge = await ethers.getContractAt("GaugeV2", gauge_addr, governanceSigner);
    }
    return Gauge;
}
