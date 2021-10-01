// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxChartLp is StrategyJoeFarmBase {
    uint256 public avax_chart_poolId = 60;

    address public joe_avax_chart_lp =
        0x8724a15D8B760BB72545488429A4032228382BDa;
    address public chart = 0xD769bDFc0CaEe933dc0a047C7dBad2Ec42CFb3E2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_chart_poolId,
            joe_avax_chart_lp,
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
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV2).deposit(poolId, 0);

        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keepJOE = _joe.mul(keep).div(keepMax);
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, chart, _amount);
        }

        // Adds in liquidity for AVAX/CHART
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _chart = IERC20(chart).balanceOf(address(this));

        if (_wavax > 0 && _chart > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(chart).safeApprove(joeRouter, 0);
            IERC20(chart).safeApprove(joeRouter, _chart);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                chart,
                _wavax,
                _chart,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(chart).safeTransfer(
                IController(controller).treasury(),
                IERC20(chart).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxChartLp";
    }
}
