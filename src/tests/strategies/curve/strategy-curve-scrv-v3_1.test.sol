// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-defi-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v3.sol";

import "../../../strategies/curve/strategy-curve-scrv-v3_1.sol";

contract StrategyCurveSCRVv3_1Test is DSTestDefiBase {
    address governance;
    address strategist;
    address timelock;

    address devfund;
    address treasury;

    PickleJar pickleJar;
    ControllerV3 controller;
    StrategyCurveSCRVv3_1 strategy;

    function setUp() public {
        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        controller = new ControllerV3(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = new StrategyCurveSCRVv3_1(
            governance,
            strategist,
            address(controller),
            timelock
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

    function _getSCRV(uint256 daiAmount) internal {
        _getERC20(dai, daiAmount);
        uint256[4] memory liquidity;
        liquidity[0] = IERC20(dai).balanceOf(address(this));
        IERC20(dai).approve(curve, liquidity[0]);
        ICurveFi_4(curve).add_liquidity(liquidity, 0);
    }

    // **** Tests ****

    function test_scrv_v3_withdraw() public {
        _getSCRV(10000000 ether); // 1 million DAI
        uint256 _scrv = IERC20(scrv).balanceOf(address(this));
        IERC20(scrv).approve(address(pickleJar), _scrv);
        pickleJar.deposit(_scrv);

        // Deposits to strategy
        pickleJar.earn();

        // Fast forwards
        hevm.warp(block.timestamp + 1 weeks);

        strategy.harvest();

        // Withdraws back to pickleJar
        uint256 _before = IERC20(scrv).balanceOf(address(pickleJar));
        controller.withdrawAll(scrv);
        uint256 _after = IERC20(scrv).balanceOf(address(pickleJar));

        assertTrue(_after > _before);

        _before = IERC20(scrv).balanceOf(address(this));
        pickleJar.withdrawAll();
        _after = IERC20(scrv).balanceOf(address(this));

        assertTrue(_after > _before);

        // Gained some interest
        assertTrue(_after > _scrv);
    }

    function test_scrv_v3_get_earn_harvest_rewards() public {
        // Deposit sCRV, and earn
        _getSCRV(10000000 ether); // 1 million DAI
        uint256 _scrv = IERC20(scrv).balanceOf(address(this));
        IERC20(scrv).approve(address(pickleJar), _scrv);
        pickleJar.deposit(_scrv);
        pickleJar.earn();

        // Fast forward one week
        hevm.warp(block.timestamp + 1 weeks);

        // Call the harvest function
        uint256 _before = pickleJar.balance();
        uint256 _treasuryBefore = IERC20(scrv).balanceOf(treasury);
        strategy.harvest();
        uint256 _after = pickleJar.balance();
        uint256 _treasuryAfter = IERC20(scrv).balanceOf(treasury);

        uint256 earned = _after.sub(_before).mul(1000).div(970);
        uint256 earnedRewards = earned.mul(45).div(1000); // 4.5%
        uint256 actualRewardsEarned = _treasuryAfter.sub(_treasuryBefore);

        // 4.5% performance fee is given
        assertEqApprox(earnedRewards, actualRewardsEarned);

        // Withdraw
        uint256 _devBefore = IERC20(scrv).balanceOf(devfund);
        _treasuryBefore = IERC20(scrv).balanceOf(treasury);
        uint256 _stratBal = strategy.balanceOf();
        pickleJar.withdrawAll();
        uint256 _devAfter = IERC20(scrv).balanceOf(devfund);
        _treasuryAfter = IERC20(scrv).balanceOf(treasury);

        // 0.125% goes to dev
        uint256 _devFund = _devAfter.sub(_devBefore);
        assertEq(_devFund, _stratBal.mul(125).div(100000));

        // 0.375% goes to treasury
        uint256 _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
        assertEq(_treasuryFund, _stratBal.mul(375).div(100000));
    }
}
