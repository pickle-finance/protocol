// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;


import "../../../lib/user.sol";
import "../../../lib/test-approx.sol";
import "../../../lib/polygon/curve/test-defi-base.sol";
import "../../../lib/polygon/curve/test-strategy-curve-farm-base.sol";

import "../../../../lib/reentrancy-guard.sol";
import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";

import "../../../../strategies/polygon/curve/strategy-curve-am3crv-v2.sol";

contract StrategyCurveAm3CRVv2Test is StrategyCurveFarmTestBase, ReentrancyGuard {
    function setUp() public {
        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        want = three_crv;

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyCurveAm3CRVv2(
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

        hevm.warp(startTime);
    }

    function _getWant(uint256 daiAmount) nonReentrant internal {
        _getERC20(dai, daiAmount);
        uint256[3] memory liquidity;
        liquidity[0] = IERC20(dai).balanceOf(address(this));
        IERC20(dai).approve(three_pool, liquidity[0]);
        (bool success, ) = three_pool.call{gas: 3000000}(abi.encodeWithSignature("add_liquidity(uint256[3],uint256,bool)", liquidity, 0, true));
        if (!success) {
            // three_pool.call(abi.encodeWithSignature("add_liquidity(uint256[3],uint256,bool)", liquidity, 0, true));
            ICurveFi_Polygon_3(three_pool).add_liquidity(liquidity, 0, true);
        }
    }

    // **** Tests **** //
    function test_3crv_withdraw() public {
        _getWant(100 ether);
        _test_withdraw();
    }

    function test_3crv_earn_harvest_rewards() public {
        _getWant(100 ether);
        _test_get_earn_harvest_rewards();
    }
}
