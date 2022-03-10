// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriLinearNearLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_linear_near_poolid = 22;
    // Token addresses
    address public tri_linear_near_lp =
        0xbceA13f9125b0E3B66e979FedBCbf7A4AfBa6fd1;
    address public linear = 0x918dBe087040A41b786f0Da83190c293DAe24749;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            linear,
            tri_linear_near_poolid,
            tri_linear_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = linear;
        swapRoutes[linear] = [tri, near, linear];
        swapRoutes[near] = [linear, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriLinearNearLp";
    }
}
