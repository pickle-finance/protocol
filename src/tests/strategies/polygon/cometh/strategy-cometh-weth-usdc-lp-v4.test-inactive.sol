pragma solidity ^0.6.7;

import "../../../lib/polygon/cometh/test-strategy-cometh-farm-base.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/cometh/strategy-cometh-weth-usdc-lp-v4.sol";

contract StrategyComethWethUsdcLpV4Test is StrategyComethFarmTestBase {
    function setUp() public {
        want = 0x1Edb2D8f791D2a51D56979bf3A25673D6E783232;
        token1 = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

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
                new StrategyComethWethUsdcLpV4(
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

    function test_wethusdcv3_1_timelock() public {
        _test_timelock();
    }

    function test_wethusdcv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_wethusdcv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
