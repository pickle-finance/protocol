// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxTimeLp is StrategyJoeFarmBase {

    uint256 public avax_time_poolId = 45;

    address public joe_avax_time_lp = 0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917;
    address public time = 0xb54f16fB19478766A268F172C9480f8da1a7c9C3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_time_poolId,
            joe_avax_time_lp,
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
            uint256 _keepJOE = _joe.mul(keepJOE).div(keepJOEMax);
            _takeFeeJoeToSnob(_keepJOE);
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, time, _amount);
        }

        // Adds in liquidity for AVAX/WBTC
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _time = IERC20(time).balanceOf(address(this));

        if (_wavax > 0 && _time > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(time).safeApprove(joeRouter, 0);
            IERC20(time).safeApprove(joeRouter, _time);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                time,
                _wavax,
                _time,
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
            IERC20(time).safeTransfer(
                IController(controller).treasury(),
                IERC20(time).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxTimeLp";
    }
}
