import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {
    AxialControllerV4__factory,
    AaveControllerV4__factory,
    BankerJoeControllerV4__factory,
    BenqiControllerV4__factory,
    ControllerV4__factory,
    PlatypusControllerV4__factory,
    TraderJoeControllerV4__factory,
} from '../../typechain';

import * as addresses from '../utils/addresses.json';
const GOVERNANCE = "governance"
const STRATEGIST = "strategist"
const TIMELOCK = "timelock"
const DEV_FUND = "devfund"
const TREASURY = "treasury" 
const COUNCIL = "council"

export const BACKUP_DEPLOYED_NAME = "BackupControllerV4";

interface ControllerInitArg {
    governance: string;
    strategist: string;
    timelock: string;
    devfund: string;
    treasury: string;
};

type ControllerInitArgs<ControllerInitArg> = { 
    [key: string]: ControllerInitArg; 
}

/*** Controller Constructor Arguements ***/
const DefaultArgs: ControllerInitArg = {
    governance: addresses[GOVERNANCE],
    strategist: addresses[STRATEGIST], 
    timelock:   addresses[TIMELOCK],
    devfund:    addresses[DEV_FUND],
    treasury:   addresses[TREASURY],
}
const ControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    strategist: addresses[TIMELOCK], 
}
const AaveControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    timelock: addresses[STRATEGIST], 
    treasury: addresses[COUNCIL],
}
const AxialControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    strategist: addresses[TIMELOCK], 
    treasury: addresses[COUNCIL],
}
const BackupControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    timelock: addresses[STRATEGIST], 
    treasury: addresses[COUNCIL],
}
const BankerJoeControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    timelock: addresses[STRATEGIST], 
    treasury: addresses[COUNCIL],
}
const BenqiControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    strategist: addresses[TIMELOCK], 
    treasury: addresses[COUNCIL],
}
const PlatypusControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    strategist: addresses[TIMELOCK], 
    treasury: addresses[COUNCIL],
}
const TraderJoeControllerArgs: ControllerInitArg = {
    ...DefaultArgs,
    governance: addresses[TREASURY],
    strategist: addresses[TIMELOCK], 
    treasury: addresses[COUNCIL],
}

const CONTROLLER_INIT_ARGS: ControllerInitArgs<ControllerInitArg> = buildControllerInitArgs();

function buildControllerInitArgs() : ControllerInitArgs<ControllerInitArg> {
    let controller_init_args : ControllerInitArgs<ControllerInitArg> = {}; 
    controller_init_args[(new AaveControllerV4__factory()).contractName] = AaveControllerArgs; 
    controller_init_args[(new AxialControllerV4__factory()).contractName] = AxialControllerArgs; 
    controller_init_args[BACKUP_DEPLOYED_NAME] = BackupControllerArgs; 
    controller_init_args[(new BankerJoeControllerV4__factory()).contractName] = BankerJoeControllerArgs; 
    controller_init_args[(new BenqiControllerV4__factory()).contractName] = BenqiControllerArgs; 
    controller_init_args[(new ControllerV4__factory()).contractName] = ControllerArgs; 
    controller_init_args[(new PlatypusControllerV4__factory()).contractName] = PlatypusControllerArgs; 
    controller_init_args[(new TraderJoeControllerV4__factory()).contractName] = TraderJoeControllerArgs; 
    return controller_init_args;
}

export function getControllerArgs(contract_name: string) : Array<string> {
    let contract_init_args = CONTROLLER_INIT_ARGS[contract_name];
    return [
        contract_init_args.governance,
        contract_init_args.strategist,
        contract_init_args.timelock,
        contract_init_args.devfund,
        contract_init_args.treasury,
    ];
}
