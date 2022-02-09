import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { getControllerArgs } from './../controllers/args';
import { DeployFunction } from 'hardhat-deploy/types';

export async function deployController(hre: HardhatRuntimeEnvironment, contract_name: string, deployment_name?: string) {
    let deployed_name: string = deployment_name !== undefined ? deployment_name : contract_name;
    const {deployments, getNamedAccounts} = hre;
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    if (deployed_name != contract_name) {
        console.log(`Deploying ${contract_name} with deployment name ${deployed_name}`);
    }
    await deploy(deployed_name, {
        from: deployer,
        args: getControllerArgs(deployed_name),
        contract: contract_name,
        log: true
    }); 
}
