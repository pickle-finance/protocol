pragma solidity ^0.6.7;

import "../../../lib/polygon/curve/test-strategy-curve-farm-base.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";
import "../../../../strategies/polygon/iron/strategy-iron-is3usd.sol";

contract StrategyIronIronUsdcLpTest is StrategyCurveFarmTestBase {
    address public ironSwap = 0x837503e8A8753ae17fB8C8151B8e6f586defCb57;

    function setUp() public {
        want = 0xb4d09ff3dA7f9e9A2BA029cb0A81A989fd7B8f17;

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
                new StrategyIronIS3USD(
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

        _getWant(100 ether);
    }

    function _getWant(uint256 daiAmount) internal {
        _getERC20(dai, daiAmount);
        uint256[] memory liquidity = new uint256[](3);
        liquidity[2] = IERC20(dai).balanceOf(address(this));
        IERC20(dai).approve(ironSwap, liquidity[2]);
        (bool success, ) = ironSwap.call{gas: 3000000}(
            abi.encodeWithSignature(
                "addLiquidity(uint256[],uint256,uint256)",
                liquidity,
                1,
                now.add(60)
            )
        );
        if (!success) {
            // add_liquidity fails at the first time but not from second time.
            IIronSwap(ironSwap).addLiquidity(liquidity, 1, now.add(60));
        }
    }

    // **** Tests **** //
    function test_is3usd_withdraw() public {
        _test_withdraw();
    }

    function test_is3usd_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
