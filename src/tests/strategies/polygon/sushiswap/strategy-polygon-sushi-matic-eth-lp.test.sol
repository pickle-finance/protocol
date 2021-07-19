pragma solidity ^0.6.7;

import "../../../lib/polygon/sushiswap/test-strategy-sushi-farm-base.sol";

import "../../../../interfaces/sushi-strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/sushiswap/strategy-sushi-matic-eth-lp.sol";

contract StrategySushiMaticEthLpTest is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0xc4e595acDD7d12feC385E5dA5D43160e8A0bAC0E;

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

        strategy = ISushiStrategy(
            address(
                new StrategySushiMaticEthLp(
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

    function test_maticethv3_1_timelock() public {
        _test_timelock();
    }

    function test_maticethv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_maticethv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
