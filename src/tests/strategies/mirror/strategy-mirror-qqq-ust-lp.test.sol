pragma solidity ^0.6.7;



import "../../lib/test-strategy-mirror-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mirror/strategy-mirror-qqq-ust-lp.sol";

contract StrategyMirrorQqqUstLpTest is StrategyMirrorFarmTestBase {
    function setUp() public {
        want = 0x9E3B47B861B451879d43BBA404c35bdFb99F0a6c; // mQQQ-UST
        token1 = 0x13B02c8dE71680e71F0820c996E4bE43c2F57d15; // mQQQ

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
                new StrategyMirrorQqqUstLp(
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

    function test_qqqustv3_1_timelock() public {
        _test_timelock();
    }

    function test_qqqustv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_qqqustv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
