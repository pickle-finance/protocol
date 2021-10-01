// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdceLinkeLp is StrategyJoeFarmBase {
    uint256 public usdc_link_poolId = 56;

    address public joe_usdc_link_lp =
        0xb9f425bC9AF072a91c423e31e9eb7e04F226B39D;
    address public usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public link = 0x5947BB275c521040051D82396192181b413227A3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            usdc_link_poolId,
            joe_usdc_link_lp,
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
            _swapTraderJoe(joe, link, _amount);
        }

        // Adds in liquidity for USDC/LINK
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));

        uint256 _link = IERC20(link).balanceOf(address(this));

        if (_usdc > 0 && _link > 0) {
            IERC20(usdc).safeApprove(joeRouter, 0);
            IERC20(usdc).safeApprove(joeRouter, _usdc);

            IERC20(link).safeApprove(joeRouter, 0);
            IERC20(link).safeApprove(joeRouter, _link);

            IJoeRouter(joeRouter).addLiquidity(
                usdc,
                link,
                _usdc,
                _link,
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
            IERC20(link).safeTransfer(
                IController(controller).treasury(),
                IERC20(link).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeUsdceLinkeLp";
    }
}
