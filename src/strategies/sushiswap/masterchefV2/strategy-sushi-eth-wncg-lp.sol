// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthWncgLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_wncg_poolId = 16;

    address public sushi_eth_wncg_lp =
        0x877d9C970B8B5501E95967Fe845B7293F63E72f7;
    address public wncg = 0xf203Ca1769ca8e9e8FE1DA9D147DB68B6c919817;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_wncg_poolId,
            sushi_eth_wncg_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and WNCG tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _wncg = IERC20(wncg).balanceOf(address(this));
        if (_wncg > 0) {
            uint256 _amount = _wncg.div(2);
            IERC20(wncg).safeApprove(sushiRouter, 0);
            IERC20(wncg).safeApprove(sushiRouter, _amount);
            _swapSushiswap(wncg, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, wncg, _amount);
        }

        // Adds in liquidity for WETH/WNCG
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _wncg = IERC20(wncg).balanceOf(address(this));

        if (_weth > 0 && _wncg > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(wncg).safeApprove(sushiRouter, 0);
            IERC20(wncg).safeApprove(sushiRouter, _wncg);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                wncg,
                _weth,
                _wncg,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(wncg).safeTransfer(
                IController(controller).treasury(),
                IERC20(wncg).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthWncgLp";
    }
}
