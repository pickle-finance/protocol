// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiTrueEthLp is StrategyMasterchefV2FarmBase {

    uint256 public sushi_tru_poolId = 8;

    address public sushi_tru_eth_lp = 0xfCEAAf9792139BF714a694f868A215493461446D;
    address public tru = 0x4C19596f5aAfF459fA38B0f7eD92F11AE6543784;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_tru_poolId,
            sushi_tru_eth_lp,
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

        // Collects Sushi and TRU tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _tru = IERC20(tru).balanceOf(address(this));
        if (_tru > 0) {
            uint256 _amount = _tru.div(2);
            IERC20(tru).safeApprove(sushiRouter, 0);
            IERC20(tru).safeApprove(sushiRouter, _amount);
            _swapSushiswap(tru, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, tru, _amount);
        }

        // Adds in liquidity for WETH/TRU
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _tru = IERC20(tru).balanceOf(address(this));

        if (_weth > 0 && _tru > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(tru).safeApprove(sushiRouter, 0);
            IERC20(tru).safeApprove(sushiRouter, _tru);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                tru,
                _weth,
                _tru,
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
            IERC20(tru).safeTransfer(
                IController(controller).treasury(),
                IERC20(tru).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiTruEthLp";
    }
}