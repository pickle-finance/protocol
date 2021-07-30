pragma solidity ^0.6.7;



import "../../../lib/polygon/sushiswap/test-strategy-masterchef-farm-base.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/iron/strategy-iron-iron-usdc-lp.sol";

contract StrategyIronIronUsdcLpTest is StrategyMasterChefFarmTestBase {
    function setUp() public {
        want = 0x85dE135fF062Df790A5f20B79120f17D3da63b2d;

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
                new StrategyIronIronUsdcLp(
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

    function test_ethusdtv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethusdtv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethusdtv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
