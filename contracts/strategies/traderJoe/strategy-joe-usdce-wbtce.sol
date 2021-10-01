// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdceWBtceLp is StrategyJoeFarmBase {
    uint256 public usdc_wbtc_poolId = 54;

    address public joe_usdc_wbtc_lp =
        0x62475f52aDd016A06B398aA3b2C2f2E540d36859;
    address public usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            usdc_wbtc_poolId,
            joe_usdc_wbtc_lp,
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

            _swapTraderJoe(joe, usdc, _amount);
            _swapTraderJoe(joe, wbtc, _amount);
        }

        // Adds in liquidity for USDC/wbtc
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));

        uint256 _wbtc = IERC20(wbtc).balanceOf(address(this));

        if (_usdc > 0 && _wbtc > 0) {
            IERC20(usdc).safeApprove(joeRouter, 0);
            IERC20(usdc).safeApprove(joeRouter, _usdc);

            IERC20(wbtc).safeApprove(joeRouter, 0);
            IERC20(wbtc).safeApprove(joeRouter, _wbtc);

            IJoeRouter(joeRouter).addLiquidity(
                usdc,
                wbtc,
                _usdc,
                _wbtc,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdc).transfer(
                IController(controller).treasury(),
                IERC20(usdc).balanceOf(address(this))
            );
            IERC20(wbtc).safeTransfer(
                IController(controller).treasury(),
                IERC20(wbtc).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeUsdceWBtceLp";
    }
}
