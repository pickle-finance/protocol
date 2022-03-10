// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriStnearNearLp is StrategyTriDualFarmBaseV2 {
    // Token/stnear pool id in MasterChef contract
    uint256 public tri_stnear_near_poolid = 12;
    // Token addresses
    address public tri_stnear_near_lp =
        0x47924Ae4968832984F4091EEC537dfF5c38948a4;
    address public stnear = 0x07F9F7f963C5cD2BBFFd30CcfB964Be114332E30;
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
            near,
            tri_stnear_near_poolid,
            tri_stnear_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[stnear] = [tri, near, stnear];
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriStnearNearLp";
    }

    function harvestTwo() public override onlyBenevolent {
        uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
        uint256 _tri = IERC20(tri).balanceOf(address(this));
        address[] memory path = [meta, stnear];

        if (swapRoutes[tri].length > 1 && _extraReward > 0) {
            address[] memory path = [meta, stnear];
            UniswapRouterV2(wannaRouter).swapExactTokensForTokens(
                _extraReward,
                0,
                path,
                address(this),
                now.add(60)
            );

            uint256 _amount = IERC20(stnear).balanceOf(address(this));

            address[] memory path2 = [stnear, near, tri];
            UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                _amount,
                0,
                path2,
                address(this),
                now.add(60)
            );

            _tri = IERC20(tri).balanceOf(address(this));
            uint256 _keepReward = _tri.mul(keepREWARD).div(keepREWARDMax);
            IERC20(tri).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );

            _tri = _tri.sub(_keepReward);
            uint256 toToken0 = _tri.div(2);
            uint256 toToken1 = _tri.sub(toToken0);

            if (swapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token0], toToken0);
            }
            if (swapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(swapRoutes[token1], toToken1);
            }
        }
    }
}
