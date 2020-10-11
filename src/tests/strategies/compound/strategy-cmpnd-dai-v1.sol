// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-defi-base.sol";

import "../../../interfaces/compound.sol";

import "../../../controller-v3.sol";
import "../../../strategies/compound/strategy-cmpd-dai-v1.sol";

contract StrategyCmpndDaiV1 is DSTestDefiBase {
    StrategyCmpdDaiV1 strategy;
    ControllerV3 controller;

    address governance;
    address strategist;
    address timelock;
    address devfund;
    address treasury;

    function setUp() public {
        governance = address(this);
        strategist = address(new User());
        timelock = address(this);
        devfund = address(new User());
        treasury = address(new User());

        controller = new ControllerV3(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = new StrategyCmpdDaiV1(
            governance,
            strategist,
            address(controller),
            timelock
        );
    }

    function test_compound_dai_balances() public {
        _getERC20(dai, 100e18);
        IERC20(dai).transfer(
            address(strategy),
            IERC20(dai).balanceOf(address(this))
        );
        strategy.deposit();

        hevm.warp(block.timestamp + 1 weeks);
        hevm.roll(block.number + 100);

        strategy.harvest();

        uint256 balanceOfWant = strategy.balanceOf();
        uint256 balUnderlying = strategy.balanceOfUnderlyingView();
        uint256 targetSupply = strategy.getTargetSupplyBalance();

        log_named_uint("balanceOfWant", balanceOfWant);
        log_named_uint("balUnderlying", balUnderlying);
        log_named_uint("targetSupply", targetSupply);
    }
}
