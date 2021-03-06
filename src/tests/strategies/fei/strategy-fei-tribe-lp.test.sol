pragma solidity ^0.6.7;



import "../../lib/test-strategy-fei-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/fei/strategy-fei-tribe-lp.sol";

contract StrategyFeiTribeLpTest is StrategyFeiFarmTestBase {
    function setUp() public {
        want = 0x9928e4046d7c6513326cCeA028cD3e7a91c7590A; // FEI-TRIBE

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
                new StrategyFeiTribeLp(
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

    function test_feitribev1_timelock() public {
        _test_timelock();
    }

    function test_feitribev1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_feitribev1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
