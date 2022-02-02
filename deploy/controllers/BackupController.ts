import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { ControllerV4__factory } from '../../typechain';
import { BACKUP_DEPLOYED_NAME, getControllerArgs } from './args';
import { deployController } from './../utils/deployController';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const contract_name = (new ControllerV4__factory()).contractName;
    await deployController(hre, contract_name, BACKUP_DEPLOYED_NAME);
};

func.tags = ['controllers', 'backup']
export default func;
