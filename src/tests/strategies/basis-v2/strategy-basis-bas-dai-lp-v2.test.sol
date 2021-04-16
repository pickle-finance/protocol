pragma solidity ^0.6.7;



import "../../lib/test-strategy-basis-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/basis-v2/strategy-basis-bas-dai-lp-v2.sol";

contract StrategyBasisBasDaiLpV2Test is StrategyBasisFarmTestBase {
    function setUp() public {
        want = 0x3E78F2E7daDe07ea685F8612F00477FD97162F1e;
        token1 = 0x106538CC16F938776c7c180186975BCA23875287; // BASv2

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
                new StrategyBasisBasDaiLpV2(
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

    function test_basdaiv3_1_timelock() public {
        _test_timelock();
    }

    function test_basdaiv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_basdaiv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
