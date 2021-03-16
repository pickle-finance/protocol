pragma solidity ^0.6.7;



import "../../lib/test-strategy-mirror-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mirror/strategy-mirror-baba-ust-lp.sol";

contract StrategyMirrorBabaUstLpTest is StrategyMirrorFarmTestBase {
    function setUp() public {
        want = 0x676Ce85f66aDB8D7b8323AeEfe17087A3b8CB363; // mBABA-UST
        token1 = 0x56aA298a19C93c6801FDde870fA63EF75Cc0aF72; // mBABA

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
                new StrategyMirrorBabaUstLp(
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

    function test_babaustv3_1_timelock() public {
        _test_timelock();
    }

    function test_babaustv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_babaustv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
