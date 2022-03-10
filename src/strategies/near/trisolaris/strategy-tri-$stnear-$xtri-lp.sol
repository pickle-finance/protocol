// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriStnearXtriLp is StrategyTriDualFarmBaseV2 {
    // Token/stnear pool id in MasterChef contract
    uint256 public tri_stnear_xtri_poolid = 11;
    // Token addresses
    address public tri_stnear_xtri_lp =
        0x5913f644A10d98c79F2e0b609988640187256373;
    address public stnear = 0x07F9F7f963C5cD2BBFFd30CcfB964Be114332E30;
    address public xtri = 0x802119e4e253D5C19aA06A5d567C5a41596D6803;
    address public meta = 0xc21Ff01229e982d7c8b8691163B0A3Cb8F357453;

    address public wannaRouter = 0xa3a1eF5Ae6561572023363862e238aFA84C72ef5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            meta,
            tri_stnear_xtri_poolid,
            tri_stnear_xtri_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[stnear] = [tri, near, stnear];
        swapRoutes[xtri] = [stnear, xtri];

        IERC20(meta).approve(wannaRouter, uint256(-1));
        IERC20(stnear).approve(sushiRouter, uint256(-1));
        IERC20(tri).approve(sushiRouter, uint56(-1));
    }

    // **** Overrides ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriStnearXtriLp";
    }

    function harvestTwo() public override onlyBenevolent {
        uint256 _meta = IERC20(meta).balanceOf(address(this));
        uint256 _tri = IERC20(tri).balanceOf(address(this));

        if (_tri > 0 && _meta > 0) {
            address[] memory path = new address[](2);
            path[0] = meta;
            path[1] = stnear;
            UniswapRouterV2(wannaRouter).swapExactTokensForTokens(
                _meta,
                0,
                path,
                address(this),
                now.add(60)
            );

            uint256 _swapAllTri = IERC20(tri).balanceOf(address(this));

            _swapSushiswapWithPath(swapRoutes[stnear], _swapAllTri);

            uint256 _stnear = IERC20(stnear).balanceOf(address(this));
            uint256 _keepReward = _stnear.mul(keepREWARD).div(keepREWARDMax);
            IERC20(stnear).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            _stnear = _stnear.sub(_keepReward);
            uint256 _stnearToSwap = _stnear.div(2);

            if (swapRoutes[xtri].length > 1 && _stnear > 0) {
                _swapSushiswapWithPath(swapRoutes[xtri], _stnearToSwap);
            }
        }
    }
}
