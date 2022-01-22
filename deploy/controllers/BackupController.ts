import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { ControllerV4__factory } from '../../typechain';
import { BACKUP_DEPLOYED_NAME, getControllerArgs } from './args';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const {deployments, getNamedAccounts} = hre;
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    const deployed = await deploy(BACKUP_DEPLOYED_NAME, {
        from: deployer,
        args: getControllerArgs(BACKUP_DEPLOYED_NAME),
        contract: (new ControllerV4__factory()).contractName,
        log: true
    }); 
};

export default func;
func.tags = ['controllers', 'backup']
