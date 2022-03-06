// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritFtm is StrategySpiritBase {

    address public lp = 0x30748322B6E34545DBe0788C421886AEB5297789;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySpiritBase(
            lp,
            spiritRouter,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[wftm] = [spirit, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritFtm";
    }

    function harvest() public override {
        uint256 _spirit = _harvestRewards();

        if (_spirit == 0) return;

        // Swap half SPIRIT amount to WFTM
        uint256 toToken0 = _spirit.div(2);
        uint256 toToken1 = _spirit.sub(toToken0);
        if (swapRoutes[token0].length > 1) {
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                toToken0,
                0,
                swapRoutes[token0],
                address(this),
                now + 60
            );
        }
        if (swapRoutes[token1].length > 1) {
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                toToken1,
                0,
                swapRoutes[token1],
                address(this),
                now + 60
            );
        }

        // Adds in liquidity for SPIRIT/WFTM
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(pairRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }
}