// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriBbtNearLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_bbt_near_poolid = 17;
    // Token addresses
    address public tri_bbt_near_lp = 0xadAbA7E2bf88Bd10ACb782302A568294566236dC;
    address public bbt = 0x4148d2Ce7816F0AE378d98b40eB3A7211E1fcF0D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            bbt,
            tri_bbt_near_poolid,
            tri_bbt_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = bbt;
        swapRoutes[near] = [bbt, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriBbtNearLp";
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
