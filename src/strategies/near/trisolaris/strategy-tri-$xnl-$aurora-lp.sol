// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriXnlAuroraLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_xnl_aurora_poolid = 13;
    // Token addresses
    address public tri_xnl_aurora_lp =
        0xb419ff9221039Bdca7bb92A131DD9CF7DEb9b8e5;
    address public xnl = 0x7cA1C28663b76CFDe424A9494555B94846205585;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            xnl,
            tri_xnl_aurora_poolid,
            tri_xnl_aurora_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = xnl;
        swapRoutes[aurora] = [xnl, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriXnlAuroraLp";
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
