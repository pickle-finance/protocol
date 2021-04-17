pragma solidity ^0.6.7;



import "../../lib/test-strategy-basis-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/basis-v2/strategy-basis-bac-dai-lp-v3.sol";

contract StrategyBasisBacDaiLpV3Test is StrategyBasisFarmTestBase {
    function setUp() public {
        want = 0xd4405F0704621DBe9d4dEA60E128E0C3b26bddbD;
        token1 = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a; // Basis Cash

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
                new StrategyBasisBacDaiLpV3(
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

    function test_bacdaiv3_1_timelock() public {
        _test_timelock();
    }

    function test_bacdaiv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_bacdaiv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
