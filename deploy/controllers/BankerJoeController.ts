import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { BankerJoeControllerV4__factory } from '../../typechain';
import { deployController } from './../utils/deployController';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const contract_name = (new BankerJoeControllerV4__factory()).contractName;
    await deployController(hre, contract_name);
};

func.tags = ['controllers', 'bankerjoe']
export default func;
