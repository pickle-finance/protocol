const hre = require("hardhat");
const { ethers, network } = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";
import {
    Signer,
    Contract
} from "ethers";
import { log } from "./log"

// Return environment variable value if it exists else return empty string
//export function getEnvVar(varName: string) : string {
//   let value: string = process.env[varName] === undefined ? "" : process.env[varName];
//   return value;
//}

export async function increaseTime(sec: number) {
    // if (sec < 60) log(`⌛ Advancing ${sec} secs`);
    // else if (sec < 3600) log(`⌛ Advancing ${Number(sec / 60).toFixed(0)} mins`);
    // else if (sec < 60 * 60 * 24) log(`⌛ Advancing ${Number(sec / 3600).toFixed(0)} hours`);
    // else if (sec < 60 * 60 * 24 * 31) log(`⌛ Advancing ${Number(sec / 3600 / 24).toFixed(0)} days`);

    await hre.network.provider.send("evm_increaseTime", [sec]);
    await hre.network.provider.send("evm_mine");
}

export async function increaseBlock(block: number) {
    //log(`⌛ Advancing ${block} blocks`);
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

export function toGwei(amount: BigNumber): string {
    return amount.div(1000000000).toString();
};

export async function overwriteTokenAmount(assetAddr: string, walletAddr: string, amount: string, slot: number = 0) {
    const index = ethers.utils.solidityKeccak256(["uint256", "uint256"], [walletAddr, slot]);
    const BN = ethers.BigNumber.from(amount)._hex.toString();
    const number = ethers.utils.hexZeroPad(BN, 32);

    await ethers.provider.send("hardhat_setStorageAt", [assetAddr, index, number]);
    await hre.network.provider.send("evm_mine");
}

export async function returnSigner(address: string): Promise<Signer> {
    await network.provider.send('hardhat_impersonateAccount', [address]);
    return ethers.provider.getSigner(address)
}

export function findSlot(address: string): number {
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

export function returnController(controller: string): string {
    let address;
    switch (controller) {
        case "main": address = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85"; break;
        case "backup": address = "0xACc69DEeF119AB5bBf14e6Aaf0536eAFB3D6e046"; break;
        case "aave": address = "0x425A863762BBf24A986d8EaE2A367cb514591C6F"; break;
        case "bankerJoe": address = "0xFb7102506B4815a24e3cE3eAA6B834BE7a5f2807"; break;
        case "benqi": address = "0x252B5fD3B1Cb07A2109bF36D5bDE6a247c6f4B59"; break;
        default: address = ""; break;
    }
    return address
}

export async function setStrategy(name: string, Controller: Contract,
    timelockSigner: Signer, asset_addr: string, strategy_addr: string) {
    const setStrategy = await Controller.connect(timelockSigner).setStrategy(asset_addr, strategy_addr);
    const tx_setStrategy = await setStrategy.wait(1);
    if (!tx_setStrategy.status) {
        console.error(`Error setting the strategy for: ${name}`);
        return;
    }
    log(`Set Strategy in the Controller for: ${name}`);
}

export async function whitelistHarvester(name: string, Strategy: Contract,
    governanceSigner: Signer, wallet_addr: string) {
    const whitelist = await Strategy.connect(governanceSigner).whitelistHarvester(wallet_addr);
    const tx_whitelist = await whitelist.wait(1);
    if (!tx_whitelist.status) {
        console.error(`Error whitelisting harvester for: ${name}`);
        return;
    }
    log(`whitelisted the harvester for: ${name}`);
}

export async function setKeeper(name: string, Strategy: Contract,
    governanceSigner: Signer, wallet_addr: string) {
    const keeper = await Strategy.connect(governanceSigner).addKeeper(wallet_addr);
    const tx_keeper = await keeper.wait(1);
    if (!tx_keeper.status) {
        console.error(`Error adding keeper for: ${name}`);
        return;
    }
    log(`added keeper for: ${name}`);
}

export async function snowglobeEarn(name: string, SnowGlobe: Contract) {
    const earn = await SnowGlobe.earn();
    const tx_earn = await earn.wait(1);
    if (!tx_earn.status) {
        console.error(`Error calling earn in the Snowglobe for: ${name}`);
        return;
    }
    log(`Called earn in the Snowglobe for: ${name}`);
}

export async function strategyFold(name: string, fold: boolean, Strategy: Contract, governanceSigner: Signer) {
    if (!fold) { return; }

    // Now leverage to max
    const leverage = await Strategy.connect(governanceSigner).leverageToMax();
    const tx_leverage = await leverage.wait(1);
    if (!tx_leverage.status) {
        console.error(`Error leveraging the strategy for: ${name}`);
        return;
    }
    log(`Leveraged the strategy for: ${name}`);
}

async function getGaugeProxy(governanceSigner: Signer, gauge_proxy_addr: string) {
    const gauge_proxy_ABI = (await ethers.getContractFactory("GaugeProxyV2")).interface;
    const GaugeProxy = new ethers.Contract(gauge_proxy_addr, gauge_proxy_ABI, governanceSigner);
    return GaugeProxy;
}

export async function addGauge(name: string, SnowGlobe: Contract, governanceSigner: Signer, gauge_proxy_addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27") {
    const GaugeProxy = await getGaugeProxy(governanceSigner, gauge_proxy_addr)
    const gauge_governance_addr = await GaugeProxy.governance();

    log(`gaugeProxy governance: ${gauge_governance_addr}`);
    const gaugeGovernanceSigner = await returnSigner(gauge_governance_addr);
    const gauge = await GaugeProxy.getGauge(SnowGlobe.address);
    if (gauge == 0) {
        const addGauge = await GaugeProxy.connect(gaugeGovernanceSigner).addGauge(SnowGlobe.address);
        const tx_addGauge = await addGauge.wait(1);
        if (!tx_addGauge.status) {
            console.error(`Error adding the gauge for: ${name}`);
            return;
        }
        log(`addGauge for ${name}`);
    }
}


/*** Zapper helpers ***/

export async function returnWalletBal(_wall: string): Promise<number> {
    return Number(ethers.utils.formatEther(await ethers.provider.getBalance(_wall)))
}

export async function returnBal(_contract: Contract, _addr: string): Promise<number> {
    return Number(ethers.utils.formatEther(await _contract.balanceOf(_addr)))
}

export function printBals(context: string, globe: number, user: number) {
    let numGlobe = Number(globe).toFixed(2);
    let numUser = Number(user).toFixed(2);
    log(`\t${context} -  Globe: ${numGlobe} LP , User: ${numUser} Token`);
}

export async function getBalances(_token: Contract, _lp: Contract, walletAddr: string, SnowGlobe: Contract) {

    const user = Number(ethers.utils.formatEther(await _token.balanceOf(walletAddr)));
    const globe = Number(ethers.utils.formatEther(await _lp.balanceOf(SnowGlobe.address)));

    return [user, globe]
}

export async function getBalancesAvax(_lp: Contract, walletSigner: Signer, SnowGlobe: Contract) {
    const user = Number(ethers.utils.formatEther(await walletSigner.getBalance()));
    const globe = Number(ethers.utils.formatEther(await _lp.balanceOf(SnowGlobe.address)));

    return [user, globe]
}

export function getContractName(_poolType: string): string {
    let contractname = "";

    // Purposefully verbose PoolType names so not to confuse with tokens symbols
    switch (_poolType) {
        case "Pangolin": contractname = "SnowglobeZapAvaxPangolin"; break;
        case "TraderJoe": contractname = "SnowglobeZapAvaxTraderJoe"; break;
        default: contractname = "POOL TYPE UNDEFINED";
    }
    return contractname
}

export function getPoolABI(_poolType: string): string {
    let abi = "";

    switch (_poolType) {
        case "Pangolin": abi = require('./../abis/PangolinABI.json'); break;
        case "TraderJoe": abi = require('./../abis/TraderJoeABI.json'); break;
        default: abi = "POOL TYPE UNDEFINED";
    }
    return abi
}

export function getLpSlot(_poolType: string): number {
    let slot
    switch (_poolType) {
        case "Pangolin": slot = 1; break;
        case "TraderJoe": slot = 1; break;
        default: slot = -1;
    }
    return slot
}
