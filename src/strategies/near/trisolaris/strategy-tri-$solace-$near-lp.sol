// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriSolaceNearLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_solace_near_poolid = 10;
    // Token addresses
    address public tri_solace_near_lp =
        0xdDAdf88b007B95fEb42DDbd110034C9a8e9746F2;
    address public solace = 0x501acE9c35E60f03A2af4d484f49F9B1EFde9f40;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            solace,
            tri_solace_near_poolid,
            tri_solace_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = solace;
        swapRoutes[near] = [solace, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriSolaceNearLp";
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
