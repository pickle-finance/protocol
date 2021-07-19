pragma solidity ^0.6.7;

import "../../../lib/hevm.sol";
import "../../../lib/user.sol";
import "../../../lib/test-approx.sol";

import "../../../../interfaces/strategy.sol";
import "../../../../interfaces/curve.sol";
import "../../../../interfaces/uniswapv2.sol";

import "../../../../pickle-jar.sol";
import "../../../../controller-v4.sol";

import "./test-quick-base.sol";

contract StrategyQuickFarmTestBase is DSTestQuickBase {
    address want;

    address governance;
    address strategist;
    address timelock;

    address devfund;
    address treasury;

    PickleJar pickleJar;
    ControllerV4 controller;
    IStrategy strategy;

    function _getWant(address token0, address token1) internal {

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        IERC20(token0).safeApprove(address(univ2), 0);
        IERC20(token0).safeApprove(address(univ2), _token0);

        IERC20(token1).safeApprove(address(univ2), 0);
        IERC20(token1).safeApprove(address(univ2), _token1);

        univ2.addLiquidity(
            token0,
            token1,
            _token0,
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
        address token0 = IUniswapV2Pair(want).token0();
        address token1 = IUniswapV2Pair(want).token1();
        _getWant(token0, token1);

        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.roll(block.number + 1000000);
        uint256 pendingRewards = strategy.getHarvestable();
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
        address token0 = IUniswapV2Pair(want).token0();
        address token1 = IUniswapV2Pair(want).token1();
        _getWant(token0, token1);

        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.roll(block.number + 100000);

        // Call the harvest function
        uint256 _before = pickleJar.balance();
        uint256 _treasuryBefore = IERC20(want).balanceOf(treasury);
        
        uint256 _pendingReward = strategy.getHarvestable();
        assertTrue(_pendingReward > 0);

        strategy.harvest();
        uint256 _after = pickleJar.balance();
        assertTrue(_after > _before);
        uint256 _treasuryAfter = IERC20(want).balanceOf(treasury);
        assertTrue(_treasuryAfter > _treasuryBefore);

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