pragma solidity ^0.6.7;

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../lib/erc20.sol";
import "../../lib/test-strategy-sushi-farm-base.sol";
import "../../../strategies/alchemix/strategy-sushi-eth-alcx-lp.sol";

contract StrategySushiEthAlcxLpTest is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0xC3f279090a47e80990Fe3a9c30d24Cb117EF91a8;
        token1 = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;

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
                new StrategySushiEthAlcxLp(
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

    function test_ethalcxv1_timelock() public {
        _test_timelock();
    }

    function test_ethalcxv1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethalcxv1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
