pragma solidity ^0.6.7;



import "../../lib/test-strategy-basis-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/basis-v1/strategy-basis-bas-dai-lp-v1.sol";

contract StrategyBasisBasDaiLpTest is StrategyBasisFarmTestBase {
    function setUp() public {
        want = 0x0379dA7a5895D13037B6937b109fA8607a659ADF;
        token1 = 0xa7ED29B253D8B4E3109ce07c80fc570f81B63696; // Bas

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
                new StrategyBasisBasDaiLp(
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
