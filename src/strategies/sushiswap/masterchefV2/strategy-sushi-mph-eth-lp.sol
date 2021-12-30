// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiMphEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_mph_eth_poolId = 4;

    address public sushi_mph_eth_lp =
        0xB2C29e311916a346304f83AA44527092D5bd4f0F;
    address public mph = 0x8888801aF4d980682e47f1A9036e589479e835C5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_mph_eth_poolId,
            sushi_mph_eth_lp,
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

        // Collects Sushi and MPH tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _mph = IERC20(mph).balanceOf(address(this));
        if (_mph > 0) {
            uint256 _amount = _mph.div(2);
            IERC20(mph).safeApprove(sushiRouter, 0);
            IERC20(mph).safeApprove(sushiRouter, _amount);
            _swapSushiswap(mph, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, mph, _amount);
        }

        // Adds in liquidity for MPH/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _mph = IERC20(mph).balanceOf(address(this));

        if (_weth > 0 && _mph > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(mph).safeApprove(sushiRouter, 0);
            IERC20(mph).safeApprove(sushiRouter, _mph);

            UniswapRouterV2(sushiRouter).addLiquidity(
                mph,
                weth,
                _mph,
                _weth,
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
            IERC20(mph).safeTransfer(
                IController(controller).treasury(),
                IERC20(mph).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiMphEthLp";
    }
}
