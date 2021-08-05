pragma solidity ^0.6.7;

import "../../lib/test-strategy-sushi-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/sushiswap/strategy-sushi-eth-yvboost-lp.sol";

contract StrategySushiEthYvBoostLpTest is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0x9461173740D27311b176476FA27e94C681b1Ea6b;
        token1 = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a; // yvboost

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
                new StrategySushiEthYvBoostLp(
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

    function test_ethyvboost_1_timelock() public {
        _test_timelock();
    }

    function test_ethyvboost_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethyvboost_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
