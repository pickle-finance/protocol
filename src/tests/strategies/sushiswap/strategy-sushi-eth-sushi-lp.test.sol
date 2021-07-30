pragma solidity ^0.6.7;

import "../../lib/test-strategy-sushi-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/sushiswap/strategy-sushi-eth-sushi-lp.sol";

contract StrategySushiEthSushiLpTest is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0x795065dCc9f64b5614C407a6EFDC400DA6221FB0;
        token1 = sushi;

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
                new StrategySushiEthSushiLp(
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

    function test_ethsushiv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethsushiv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethsushiv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
