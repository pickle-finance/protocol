pragma solidity ^0.6.7;

import "../../../lib/polygon/cometh/test-strategy-cometh-farm-base.sol";
import "../../../lib/polygon/cometh/test-strategy-cometh-farm-base-v2.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/cometh/strategy-cometh-pickle-must-lp-v4.sol";

contract StrategyComethPickleMustLpV4Test is StrategyComethFarmTestBaseV2 {
    function setUp() public {
        want = 0xb0b5E3Bd18eb1E316bcD0bBa876570b3c1779C55;

        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyComethPickleMustLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
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

        // Set time
        hevm.warp(startTime);
    }

    // **** Tests ****

    function test_picklemustv3_1_timelock() public {
        _test_timelock();
    }

    function test_picklemustv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_picklemustv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
