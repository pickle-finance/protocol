import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { AaveControllerV4__factory } from '../../typechain';
import { deployController } from './../utils/deployController';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const contract_name = (new AaveControllerV4__factory()).contractName;
    await deployController(hre, contract_name);
};

func.tags = ['controllers', 'aave']
export default func;
