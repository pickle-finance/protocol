// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-bxh-farm-base.sol";
import "../../interfaces/xusdt.sol";

contract StrategyBxhXusdtStaking is StrategyBxhFarmBase {
    uint256 public xusdt_staking_poolId = 1;

    // Token addresses
    address public xusdt = 0x8E017294cB690744eE2021f9ba75Dd1683f496fb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBxhFarmBase(
            xusdt, // unused
            xusdt, // unused
            xusdt_staking_poolId,
            xusdt,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects BXH tokens
        IBxhChef(bxhChef).deposit(poolId, 0);
        uint256 _bxh = IERC20(bxh).balanceOf(address(this));

        if (_bxh > 0) {
            _swapSushiswapWithPath([bxh, usdt], _bxh);
        }

        // Stake USDT for XUSDT
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));

        if (_usdt > 0) {
            IERC20(usdt).safeApprove(xusdt, 0);
            IERC20(usdt).safeApprove(xusdt, _usdt);

            IXusdt(xusdt).stake(_usdt);

            uint256 _xusdt = IERC20(xusdt).balanceOf(address(this));

            // Donates DUST
            IERC20(bxh).transfer(
                IController(controller).treasury(),
                IERC20(bxh).balanceOf(address(this))
            );
            IERC20(usdt).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdt).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBxhXusdtStaking";
    }
}
