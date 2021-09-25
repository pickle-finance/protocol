// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdtELinkELp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 34;

    address public joe_usdt_link_lp = 0x59E4e5501764a293B829902D9CF01967FA80eff2;
    address public usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public link = 0x5947BB275c521040051D82396192181b413227A3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_usdt_link_lp,
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

            _swapTraderJoe(joe, usdt, _amount);
            _swapTraderJoe(joe, link, _amount);
        }

        // Adds in liquidity for USDT.e/LINK.e
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));
        uint256 _link = IERC20(link).balanceOf(address(this));

        if (_usdt > 0 && _joe > 0) {
            IERC20(usdt).safeApprove(joeRouter, 0);
            IERC20(usdt).safeApprove(joeRouter, _usdt);

            IERC20(link).safeApprove(joeRouter, 0);
            IERC20(link).safeApprove(joeRouter, _link);

            IJoeRouter(joeRouter).addLiquidity(
                usdt,
                link,
                _usdt,
                _link,
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
            IERC20(link).safeTransfer(
                IController(controller).treasury(),
                IERC20(link).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdtELinkELp";
    }
}
