const hre = require("hardhat")
const { ethers } = require("hardhat")
import { 
   Contract, 
   ContractFactory, 
   Signer 
} from "ethers";
import { getContractName } from "../utils/helpers";

export async function setupMockZapper(pool_type: string) {
    let contractType = getContractName(pool_type);
    const zapperFactory: ContractFactory = await ethers.getContractFactory(contractType);
    let Zapper: Contract = await zapperFactory.deploy();
    return Zapper;
}
