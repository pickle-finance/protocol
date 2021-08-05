pragma solidity ^0.6.7;

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../lib/erc20.sol";
import "../../lib/test-strategy-sushi-farm-base.sol";
import "../../../strategies/convex/strategy-sushi-cvx-eth-lp.sol";

contract StrategySushiCvxEthLpTest is StrategySushiFarmTestBase {
    function setUp() public {
        want = 0x05767d9EF41dC40689678fFca0608878fb3dE906;
        token1 = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

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
                new StrategySushiCvxEthLp(
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

    function test_ethcvx_timelock() public {
        _test_timelock();
    }

    function test_ethcvx_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethcvx_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}