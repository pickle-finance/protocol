pragma solidity ^0.6.7;



import "../../lib/test-strategy-1inch-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/1inch/strategy-1inch-eth-opium-lp.sol";

contract Strategy1inchEthOpiumLpTest is Strategy1inchFarmTestBase {
    function setUp() public {
        want = 0x822E00A929f5A92F3565A16f92581e54af2b90Ea;
        token1 = 0x888888888889C00c67689029D7856AAC1065eC11;
        pool = 0x18D410f651289BB978Fc32F90D2d7E608F4f4560;

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
                new Strategy1inchEthOpiumLp(
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
