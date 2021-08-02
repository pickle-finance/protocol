pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../../lib/test-strategy-lqty-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/liquity/strategy-lqty.sol";

contract StrategyLqtyTest is StrategyLqtyFarmTestBase {
    function setUp() public {
        want = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;

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
                new StrategyLqty(
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

    function test_lqty_timelock() public {
        _test_timelock();
    }

    function test_lqty_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_lqty_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
