pragma solidity ^0.6.7;



import "../../lib/test-strategy-opium-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/opium/strategy-sushi-opium-eth-lp.sol";

contract StrategySushiOpiumEthLpTest is StrategyOpiumFarmTestBase {
    function setUp() public {
        want = 0xD84d55532B231DBB305908bc5A10B8c55ba21e5E; // Sushiswap Opium-WETH
        token1 = 0x888888888889C00c67689029D7856AAC1065eC11; // Opium

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
                new StrategySushiOpiumEthLp(
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

    function test_opiumethv3_1_timelock() public {
        _test_timelock();
    }

    function test_opiumethv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_opiumethv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
