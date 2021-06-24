pragma solidity ^0.6.7;

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";

import "../../../interfaces/yearn-strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";

import "../../lib/test-defi-base.sol";
import "../../../strategies/yearn/strategy-yearn-usdc-v2.sol";
import "../../../strategies/convex/strategy-sushi-cvx-eth-lp.sol";

contract StrategyYearnUsdcV2Test is DSTestDefiBase {
    
    address want;

    address governance;
    address strategist;
    address timelock;

    address devfund;
    address treasury;

    PickleJar pickleJar;
    ControllerV4 controller;
    IYearnStrategy strategy;

    function setUp() public {
        want = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

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

        strategy = IYearnStrategy(
            address(
                new StrategyYearnUsdcV2(
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


    function _getWant(uint256 wantAmount) public {
        _getERC20(want, wantAmount);
    }

    // **** Tests ****


    function test_withdraw_all() public {
        uint256 decimals = ERC20(want).decimals();
        _getWant(4000 * (10**decimals));
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        uint256 _before = IERC20(want).balanceOf(address(this));
        pickleJar.deposit(_want);
        pickleJar.earn();

        // Checking withdraw
        pickleJar.withdrawAll();
        uint256 _after = IERC20(want).balanceOf(address(this));
        assertEqApprox(_after, _before);
    }

    function test_withdraw_half() public {
        uint256 decimals = ERC20(want).decimals();
        _getWant(4000 * (10**decimals));
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        uint256 _before = IERC20(want).balanceOf(address(this));
        pickleJar.deposit(_want);
        pickleJar.earn();

        // Checking withdraw
        pickleJar.withdraw(_want.div(2));
        uint256 _after = IERC20(want).balanceOf(address(this));
        assertEqApprox(_after, _before.div(2));
    }
}
