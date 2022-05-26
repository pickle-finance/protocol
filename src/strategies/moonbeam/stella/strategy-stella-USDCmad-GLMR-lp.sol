// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-stella-farm-base-v2.sol";

contract StrategyStellaUSDCmadGLMRLp is StrategyStellaFarmBaseV2 {
    uint256 public USDCmad_glmr_poolId = 12;

    // Token addresses
    address public USDCmad_glmr_lp = 0x9bFcf685e641206115dadc0C9ab17181e1d4975c;
    address public USDCmad = 0x8f552a71EFE5eeFc207Bf75485b356A0b3f01eC9;
    address public rewarderContract = 0x9200Cb047A9c4b34A17cCF86334E3f434f948301;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBaseV2(
            USDCmad_glmr_lp,
            USDCmad_glmr_poolId,
            rewarderContract,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [stella, glmr];
        swapRoutes[USDCmad] = [glmr, USDCmad];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaUSDCmadGlmrLp";
    }
}
