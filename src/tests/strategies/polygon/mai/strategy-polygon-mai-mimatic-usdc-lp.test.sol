pragma solidity ^0.6.7;



import "../../../lib/polygon/quick/test-strategy-quick-farm-base.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/mai/strategy-mai-mimatic-usdc-lp.sol";

contract StrategyMaiMiMaticUsdcLpTest is StrategyQuickFarmTestBase {
    // Token addresses
    address mimatic = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
    address[] mimaticPath = [wmatic, usdc, mimatic];
    address[] usdcPath = [wmatic, usdc];

    function setUp() public {
        want = 0x160532D2536175d65C03B97b0630A9802c274daD;

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
                new StrategyMaiMiMaticUsdcLp(
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

    function test_ethusdtv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethusdtv3_1_withdraw_release() public {
        _getTokenWithPath(mimatic, 100, mimaticPath);
        _getTokenWithPath(usdc, 100, usdcPath);
        _test_withdraw_release();
    }

    function test_ethusdtv3_1_get_earn_harvest_rewards() public {
        _getTokenWithPath(mimatic, 100, mimaticPath);
        _getTokenWithPath(usdc, 100, usdcPath);
        _test_get_earn_harvest_rewards();
    }
}
