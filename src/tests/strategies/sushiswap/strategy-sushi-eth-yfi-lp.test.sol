pragma solidity ^0.6.7;



import "../../lib/test-strategy-sushi-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/sushiswap/strategy-sushi-eth-yfi-lp.sol";

contract StrategySushiEthYfiLpV2Test is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0x088ee5007C98a9677165D78dD2109AE4a3D04d0C;
        token1 = yfi;

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
                new StrategySushiEthYfiLp(
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

    function test_ethyfiv1_timelock() public {
        _test_timelock();
    }

    function test_ethyfiv1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethyfiv1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
