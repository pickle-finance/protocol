// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthSiLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_si_poolId = 10;

    address public sushi_eth_si_lp = 0x30045ad74f4475E82DcDC269952581ECb7CD2bAd;
    address public si = 0xD23Ac27148aF6A2f339BD82D0e3CFF380b5093de;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_si_poolId,
            sushi_eth_si_lp,
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

        // Collects Sushi and SI tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _si = IERC20(si).balanceOf(address(this));
        if (_si > 0) {
            uint256 _amount = _si.div(2);
            IERC20(si).safeApprove(sushiRouter, 0);
            IERC20(si).safeApprove(sushiRouter, _amount);
            _swapSushiswap(si, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, si, _amount);
        }

        // Adds in liquidity for WETH/SI
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _si = IERC20(si).balanceOf(address(this));

        if (_weth > 0 && _si > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(si).safeApprove(sushiRouter, 0);
            IERC20(si).safeApprove(sushiRouter, _si);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                si,
                _weth,
                _si,
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
            IERC20(si).safeTransfer(
                IController(controller).treasury(),
                IERC20(si).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthSiLp";
    }
}
