// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlUsdcNearLp is StrategyBrlFarmBase {
    uint256 public usdc_near_poolid = 3;
    // Token addresses
    address public usdc_near_lp = 0x480A68bA97d70495e80e11e05D59f6C659749F27;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            usdc,
            near,
            usdc_near_poolid,
            usdc_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[usdc] = [brl, near, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlUsdcNearLp";
    }
}
