// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-stella-farm-base-v2.sol";

contract StrategyStellaETHmadGLMRLp is StrategyStellaFarmBaseV2 {
    uint256 public ETHmad_glmr_poolId = 11;

    // Token addresses
    address public ETHmad_glmr_lp = 0x9d19EDBFd29D2e01537624B25806493dA0d73bBE;
    address public ETHmad = 0x30D2a9F5FDf90ACe8c17952cbb4eE48a55D916A7;
    address public rewarderContract = 0x9Fe074a56FFa7f4079C6190be6E8452911b7E349;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBaseV2(
            ETHmad_glmr_lp,
            ETHmad_glmr_poolId,
            rewarderContract,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [stella, glmr];
        swapRoutes[ETHmad] = [glmr, ETHmad];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaEthGlmrLp";
    }
}
