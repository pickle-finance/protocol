// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-dual-rewards-base.sol";


contract StrategyLqdrDeiUsdc is StrategyLqdrDualFarmLPBase {
    uint256 public _poolId = 36;
    // Token addresses
    address public _lp = 0x8eFD36aA4Afa9F4E157bec759F1744A7FeBaEA0e;
    address public dei = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public deus = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;

    // Spiritswap router
    address public router = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyLqdrDualFarmLPBase(
            _lp,
            _poolId,
            router,
            _governance,
            _strategist,
            _controller,
            _timelock,
            deus
        )
    {
        swapRoutes[dei] = [wftm, usdc, dei];
        swapRoutes[usdc] = [wftm, usdc];
        IERC20(deus).approve(sushiRouter, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrDeiUsdc";
    }

    function harvest() public virtual override {
        ILqdrChef(masterchef).harvest(poolId, address(this));
        uint256 _lqdr = IERC20(lqdr).balanceOf(address(this));
        uint256 _reward = IERC20(deus).balanceOf(address(this));

        if (_lqdr == 0 && _reward == 0) return;
        uint256 _keepLQDR = _lqdr.mul(keepLQDR).div(keepLQDRMax);
        uint256 _keepReward = _reward.mul(keepLQDR).div(keepLQDRMax);
        IERC20(lqdr).safeTransfer(
            IController(controller).treasury(),
            _keepLQDR
        );
        IERC20(deus).safeTransfer(
            IController(controller).treasury(),
            _keepReward
        );

        _lqdr = _lqdr.sub(_keepLQDR);
        _reward = _reward.sub(_keepReward);

        _swapSushiswap(lqdr, wftm, _lqdr);
        _swapSushiswap(deus, wftm, _reward);

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[1] = wftm;

        if (token0 != wftm && _token0 > 0) {
            path[0] = token0;
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                _token0,
                0,
                path,
                address(this),
                block.timestamp.add(60)
            );
        }

        if (token1 != wftm && _token1 > 0) {
            path[0] = token1;
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                _token1,
                0,
                path,
                address(this),
                block.timestamp.add(60)
            );
        }

        uint256 _wftm = IERC20(wftm).balanceOf(address(this));

        uint256 toToken0 = _wftm.div(2);
        uint256 toToken1 = _wftm.sub(toToken0);

        if (swapRoutes[token0].length > 1) {
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                toToken0,
                0,
                swapRoutes[token0],
                address(this),
                block.timestamp.add(60)
            );
        }
        if (swapRoutes[token1].length > 1) {
            UniswapRouterV2(pairRouter).swapExactTokensForTokens(
                toToken1,
                0,
                swapRoutes[token1],
                address(this),
                block.timestamp.add(60)
            );
        }

        // Adds in liquidity for token0/token1
        _token0 = IERC20(token0).balanceOf(address(this));
        _token1 = IERC20(token1).balanceOf(address(this));

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
