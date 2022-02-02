import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { AaveControllerV4__factory } from '../../typechain';
import { getControllerArgs } from './args';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const {deployments, getNamedAccounts} = hre;
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    const contract_name = (new AaveControllerV4__factory()).contractName;
    const deployed = await deploy(contract_name, {
        from: deployer,
        args: getControllerArgs(contract_name),
        contract: contract_name,
        log: true
    }); 
};

func.tags = ['controllers', 'aave']
export default func;
