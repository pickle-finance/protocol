// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriGbaUsdtLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_gba_usdt_poolid = 15;
    // Token addresses
    address public tri_gba_usdt_lp = 0x7B273238C6DD0453C160f305df35c350a123E505;
    address public gba = 0xc2ac78FFdDf39e5cD6D83bbD70c1D67517C467eF;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            gba,
            tri_gba_usdt_poolid,
            tri_gba_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = gba;
        swapRoutes[usdt] = [gba, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriGbaUsdtLp";
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
