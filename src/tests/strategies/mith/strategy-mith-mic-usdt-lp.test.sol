pragma solidity ^0.6.7;



import "../../lib/test-strategy-mith-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/mith/strategy-mith-mic-usdt-lp.sol";

contract StrategyMithMicUsdtLpTest is StrategyMithFarmTestBase {
    function setUp() public {
        want = 0xC9cB53B48A2f3A9e75982685644c1870F1405CCb; // Sushiswap MIC-USDT
        token1 = 0x368B3a58B5f49392e5C9E4C998cb0bB966752E51; // MIC

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
                new StrategyMithMicUsdtLp(
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

    function test_ethdaiv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethdaiv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethdaiv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
