pragma solidity ^0.6.7;

import "../../lib/test-strategy-sushi-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/sushiswap/strategy-sushi-eth-yvecrv-lp.sol";

contract StrategySushiEthYVeCrvLpTest is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0x10B47177E92Ef9D5C6059055d92DdF6290848991;
        token1 = 0xc5bDdf9843308380375a611c18B50Fb9341f502A; // yvecrv

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
                new StrategySushiEthYVeCrvLp(
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

    function test_ethyvecrvv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethvecrvv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethvecrvv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
