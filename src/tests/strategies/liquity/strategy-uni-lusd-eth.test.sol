pragma solidity ^0.6.7;

import "../../lib/test-strategy-uni-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/liquity/strategy-uni-lusd-eth-lp.sol";

contract StrategyLusdEthLpTest is StrategyUniFarmTestBase {
    function setUp() public {
        want = 0xF20EF17b889b437C151eB5bA15A47bFc62bfF469;
        token1 = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

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
                new StrategyLusdEthLp(
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

    function test_lusd_eth_timelock() public {
        _test_timelock();
    }

    function test_lusd_eth_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_lusd_eth_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
