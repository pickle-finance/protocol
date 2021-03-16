pragma solidity ^0.6.7;



import "../../lib/test-strategy-mirror-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mirror/strategy-mirror-tsla-ust-lp.sol";

contract StrategyMirrorTslaUstLpTest is StrategyMirrorFarmTestBase {
    function setUp() public {
        want = 0x5233349957586A8207c52693A959483F9aeAA50C; // Tsla-UST
        token1 = 0x21cA39943E91d704678F5D00b6616650F066fD63; // Tsla

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
                new StrategyMirrorTslaUstLp(
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

    function test_tslaustv3_1_timelock() public {
        _test_timelock();
    }

    function test_tslaustv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_tslaustv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
