// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-beam-farm-base.sol";

contract StrategyGlintUsdcGlmrLp is StrategyBeamFarmBase {
    uint256 public usdc_glmr_poolId = 1;

    // Token addresses
    address public usdc_glmr_lp = 0xb929914B89584b4081C7966AC6287636F7EfD053;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBeamFarmBase(
            usdc_glmr_lp,
            usdc_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [glint, glmr];
        swapRoutes[usdc] = [glint, glmr, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintUsdcGlmrLp";
    }
}
