pragma solidity ^0.6.7;



import "../../../lib/polygon/mimatic/test-strategy-mimatic-farm-base.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar-deposit-fee-initializable.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/mai/strategy-mai-mimatic-usdc-lp.sol";

contract StrategyMaiMiMaticUsdcLpTest is StrategyMimaticFarmTestBase {
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

        pickleJar = new PickleJarDepositFeeInitializable(
            strategy.want(),
            governance,
            timelock,
            address(controller),
            50
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

    function test_deposit_fee() public {
        _getTokenWithPath(mimatic, 100, mimaticPath);
        _getTokenWithPath(usdc, 100, usdcPath);
        address token0 = IUniswapV2Pair(want).token0();
        address token1 = IUniswapV2Pair(want).token1();
        _getWant(token0, token1);

        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), 10000);
        pickleJar.deposit(10000);
        pickleJar.earn();
        controller.withdrawAll(want);
        
        uint256 _before = IERC20(want).balanceOf(address(this));
        pickleJar.withdrawAll();
        uint256 _after = IERC20(want).balanceOf(address(this));

        uint256 _want = _after.sub(_before);
        assertTrue(_want == 9950);
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
