pragma solidity ^0.6.7;



import "../../lib/test-strategy-mith-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mith/strategy-mith-mis-usdt-lp.sol";

contract StrategyMithMisUsdtLpTest is StrategyMithFarmTestBase {
    function setUp() public {
        want = 0x066F3A3B7C8Fa077c71B9184d862ed0A4D5cF3e0; // Sushiswap MIS-USDT
        token1 = 0x4b4D2e899658FB59b1D518b68fe836B100ee8958; // MIS

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
                new StrategyMithMisUsdtLp(
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

    function test_misusdtv3_1_timelock() public {
        _test_timelock();
    }

    function test_misusdtv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_misusdtv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
