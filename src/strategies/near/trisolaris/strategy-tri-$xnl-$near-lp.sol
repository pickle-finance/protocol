// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriXnlNearLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_xnl_near_poolid = 14;
    // Token addresses
    address public tri_xnl_near_lp = 0xFBc4C42159A5575a772BebA7E3BF91DB508E127a;
    address public xnl = 0x7cA1C28663b76CFDe424A9494555B94846205585;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            xnl,
            tri_xnl_near_poolid,
            tri_xnl_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = xnl;
        swapRoutes[near] = [xnl, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriXnlNearLp";
    }

    function harvestTwo() public override onlyBenevolent {
        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));

        if (_extraReward > 0) {
            uint256 _keepReward = _extraReward.mul(keepREWARD).div(
                keepREWARDMax
            );
            IERC20(extraReward).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            _extraReward = IERC20(extraReward).balanceOf(address(this));
            address toToken = extraReward == token0 ? token1 : token0;

            if (swapRoutes[toToken].length > 1) {
                _swapSushiswapWithPath(
                    swapRoutes[toToken],
                    _extraReward.div(2)
                );
            }
        }
    }
}
