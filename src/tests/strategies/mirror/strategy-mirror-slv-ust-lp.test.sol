pragma solidity ^0.6.7;



import "../../lib/test-strategy-mirror-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mirror/strategy-mirror-slv-ust-lp.sol";

contract StrategyMirrorSlvUstLpTest is StrategyMirrorFarmTestBase {
    function setUp() public {
        want = 0x860425bE6ad1345DC7a3e287faCBF32B18bc4fAe; // mSLV-UST
        token1 = 0x9d1555d8cB3C846Bb4f7D5B1B1080872c3166676; // mSLV

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
                new StrategyMirrorSlvUstLp(
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

    function test_slvustv3_1_timelock() public {
        _test_timelock();
    }

    function test_slvustv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_slvustv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
