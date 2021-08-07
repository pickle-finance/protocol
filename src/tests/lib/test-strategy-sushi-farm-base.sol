pragma solidity ^0.6.7;

import "../lib/hevm.sol";
import "../lib/user.sol";
import "../lib/test-approx.sol";
import "../lib/test-sushi-base.sol";

import "../../interfaces/strategy.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";

import "../../pickle-jar.sol";
import "../../controller-v4.sol";

contract StrategySushiFarmTestBase is DSTestSushiBase {
    address want;
    address token1;

    address governance;
    address strategist;
    address timelock;

    address devfund;
    address treasury;

    PickleJar pickleJar;
    ControllerV4 controller;
    IStrategy strategy;

    function _getWant(uint256 ethAmount, uint256 amount) internal {
        _getERC20(token1, amount);

        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        IERC20(token1).safeApprove(address(sushiRouter), 0);
        IERC20(token1).safeApprove(address(sushiRouter), _token1);

        sushiRouter.addLiquidityETH{value: ethAmount}(
            token1,
            _token1,
            0,
            0,
            address(this),
            now + 60
        );
    }

    // **** Tests ****

    function _test_timelock() internal {
        assertTrue(strategy.timelock() == timelock);
        strategy.setTimelock(address(1));
        assertTrue(strategy.timelock() == address(1));
    }

    function _test_withdraw_release() internal {
        uint256 decimals = ERC20(token1).decimals();
        _getWant(10 ether, 400 * (10**decimals));
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.roll(block.number + 1000);
        strategy.harvest();

        hevm.roll(block.number + 1000);
        strategy.harvest();
        // Checking withdraw
        uint256 _before = IERC20(want).balanceOf(address(pickleJar));
        controller.withdrawAll(want);
        uint256 _after = IERC20(want).balanceOf(address(pickleJar));
        assertTrue(_after > _before);
        _before = IERC20(want).balanceOf(address(this));
        pickleJar.withdrawAll();
        _after = IERC20(want).balanceOf(address(this));
        assertTrue(_after > _before);

        // Check if we gained interest
        assertTrue(_after > _want);
    }

    function _test_get_earn_harvest_rewards() internal {
        uint256 decimals = ERC20(token1).decimals();
        _getWant(10 ether, 400 * (10**decimals));
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.roll(block.number + 1000);

        // Call the harvest function
        uint256 _before = pickleJar.balance();
        uint256 _treasuryBefore = IERC20(want).balanceOf(treasury);
        strategy.harvest();

        hevm.roll(block.number + 1000);

        strategy.harvest();
        uint256 _after = pickleJar.balance();
        uint256 _treasuryAfter = IERC20(want).balanceOf(treasury);

        uint256 earned = _after.sub(_before).mul(1000).div(800);
        uint256 earnedRewards = earned.mul(200).div(1000); // 20%
        uint256 actualRewardsEarned = _treasuryAfter.sub(_treasuryBefore);

        // 20% performance fee is given
        assertEqApprox(earnedRewards, actualRewardsEarned);

        // Withdraw
        uint256 _devBefore = IERC20(want).balanceOf(devfund);
        _treasuryBefore = IERC20(want).balanceOf(treasury);
        uint256 _stratBal = strategy.balanceOf();
        pickleJar.withdrawAll();
        uint256 _devAfter = IERC20(want).balanceOf(devfund);
        _treasuryAfter = IERC20(want).balanceOf(treasury);

        // 0% goes to dev
        uint256 _devFund = _devAfter.sub(_devBefore);
        assertEq(_devFund, 0);

        // 0% goes to treasury
        uint256 _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
        assertEq(_treasuryFund, 0);
    }
}
