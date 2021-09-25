// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdtEWbtcELp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 32;

    address public joe_usdt_wbtc_lp = 0xB8D5E8a9247db183847c7D79af9C67F6aeF759f7;
    address public usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_usdt_wbtc_lp,
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
            _swapTraderJoe(joe, wbtc, _amount);
        }

        // Adds in liquidity for USDT.e/WBTC.e
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));
        uint256 _wbtc = IERC20(wbtc).balanceOf(address(this));

        if (_usdt > 0 && _joe > 0) {
            IERC20(usdt).safeApprove(joeRouter, 0);
            IERC20(usdt).safeApprove(joeRouter, _usdt);

            IERC20(wbtc).safeApprove(joeRouter, 0);
            IERC20(wbtc).safeApprove(joeRouter, _wbtc);

            IJoeRouter(joeRouter).addLiquidity(
                usdt,
                wbtc,
                _usdt,
                _wbtc,
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
            IERC20(wbtc).safeTransfer(
                IController(controller).treasury(),
                IERC20(wbtc).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdtEWbtcELp";
    }
}
