// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdtJoeLp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 13;

    address public joe_usdt_joe_lp = 0x29e0120dE4406E9B2e28b15937B67EAe5e50C510;
    address public usdt = 0xde3A24028580884448a5397872046a019649b084;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_usdt_joe_lp,
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
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _amount);

            _swapTraderJoe(joe, usdt, _amount);
        }

        // Adds in liquidity for AVAX/JOE
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));

        _joe = IERC20(joe).balanceOf(address(this));

        if (_usdt > 0 && _joe > 0) {
            IERC20(usdt).safeApprove(joeRouter, 0);
            IERC20(usdt).safeApprove(joeRouter, _usdt);

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            IJoeRouter(joeRouter).addLiquidity(
                usdt,
                joe,
                _usdt,
                _joe,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdt).transfer(
                IController(controller).treasury(),
                IERC20(usdt).balanceOf(address(this))
            );
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                IERC20(joe).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdtJoeLp";
    }
}
