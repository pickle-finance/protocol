pragma solidity ^0.6.7;



import "../../lib/test-strategy-mirror-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mirror/strategy-mirror-aapl-ust-lp.sol";

contract StrategyMirrorTslaUstLpTest is StrategyMirrorFarmTestBase {
    function setUp() public {
        want = 0xB022e08aDc8bA2dE6bA4fECb59C6D502f66e953B; // UST-mAAPL
        token1 = 0xd36932143F6eBDEDD872D5Fb0651f4B72Fd15a84; // mAAPl

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
                new StrategyMirrorAaplUstLp(
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

    function test_aaplustv3_1_timelock() public {
        _test_timelock();
    }

    function test_aaplustv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_aaplustv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
