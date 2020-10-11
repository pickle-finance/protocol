// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-defi-base.sol";

import "../../../interfaces/compound.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v3.sol";

import "../../../strategies/compound/strategy-cmpd-dai-v1.sol";

contract StrategyCmpndDaiV1 is DSTestDefiBase {
    StrategyCmpdDaiV1 strategy;
    ControllerV3 controller;
    PickleJar pickleJar;

    address governance;
    address strategist;
    address timelock;
    address devfund;
    address treasury;

    address want;

    function setUp() public {
        want = dai;

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

        pickleJar = new PickleJar(
            strategy.want(),
            governance,
            timelock,
            address(controller)
        );

        controller.setJar(strategy.want(), address(pickleJar));
        controller.approveStrategy(strategy.want(), address(strategy));
        controller.setStrategy(strategy.want(), address(strategy));
    }

    function test_compound_dai_balances() public {
        _getERC20(want, 100e18);

        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).approve(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        strategy.maxLeverage();

        hevm.warp(block.timestamp + 1 weeks);
        hevm.roll(block.number + 100);

        strategy.harvest();
    }
}
