// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaUsdcGlmrLp is StrategyStellaFarmBase {
    uint256 public usdc_glmr_poolId = 5;

    // Token addresses
    address public usdc_glmr_lp = 0x555B74dAFC4Ef3A5A1640041e3244460Dc7610d1;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            usdc_glmr_lp,
            usdc_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [stella, glmr];
        swapRoutes[usdc] = [stella, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaUsdcGlmrLp";
    }
}
