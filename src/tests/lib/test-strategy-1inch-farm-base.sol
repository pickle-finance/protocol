pragma solidity ^0.6.7;

import "./hevm.sol";
import "./user.sol";
import "./test-approx.sol";
import "../../lib/erc20.sol";

import "../../interfaces/strategy.sol";
import "../../interfaces/1inch-farm-lp.sol";

import "../../pickle-jar.sol";
import "../../controller-v4.sol";

contract Strategy1inchFarmTestBase is DSTestApprox {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address want;
    address token1;
    address pool;

    address governance;
    address strategist;
    address timelock;

    address devfund;
    address treasury;

    IMooniswap mooniswap;

    uint256 startTime = block.timestamp;
    Hevm hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    PickleJar pickleJar;
    ControllerV4 controller;
    IStrategy strategy;

    function _getWant(uint256 ethAmount, uint256 amount) internal {
        mooniswap = IMooniswap(want);

        uint256 inAmount = mooniswap.getReturn(IERC20(token1), IERC20(address(0)), amount); 

        mooniswap.swap{value: inAmount}(IERC20(address(0)), IERC20(token1), inAmount, 0, address(0));

        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        IERC20(token1).safeApprove(address(mooniswap), 0);
        IERC20(token1).safeApprove(address(mooniswap), _token1);

        uint256[2] memory maxAmounts;
        uint256[2] memory minAmounts;
        maxAmounts[0] = ethAmount;
        maxAmounts[1] = _token1;
        minAmounts[0] = 0;
        minAmounts[1] = 0;

        mooniswap.deposit{value: ethAmount}(maxAmounts, minAmounts);
    }

    // **** Tests ****

    function _test_timelock() internal {
        assertTrue(strategy.timelock() == timelock);
        strategy.setTimelock(address(1));
        assertTrue(strategy.timelock() == address(1));
    }

    function _test_withdraw_release() internal {
        uint256 decimals = ERC20(token1).decimals();
        _getWant(10 ether, 1000 * (10**decimals));
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.warp(block.timestamp + 32 weeks);
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
        assertTrue(_after >= _want);
    }

    function _test_get_earn_harvest_rewards() internal {
        uint256 decimals = ERC20(token1).decimals();
        _getWant(10 ether, 1000 * (10**decimals));
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(address(pickleJar), 0);
        IERC20(want).safeApprove(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.warp(block.timestamp + 4 weeks);

        // Call the harvest function
        uint256 _before = pickleJar.balance();
        uint256 _treasuryBefore = IERC20(want).balanceOf(treasury);
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
    receive() external payable {}
}
