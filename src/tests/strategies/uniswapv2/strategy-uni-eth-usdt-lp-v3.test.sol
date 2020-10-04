pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-defi-base.sol";

import "../../../interfaces/usdt.sol";
import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v3.sol";
import "../../../strategies/uniswapv2/strategy-uni-eth-usdt-lp-v3.sol";

contract StrategyUniEthUsdtLpV3Test is DSTestDefiBase {
    address want = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;

    address governance;
    address strategist;
    address timelock;

    address devfund;
    address treasury;

    PickleJar pickleJar;
    ControllerV3 controller;
    StrategyUniEthUsdtLpV3 strategy;

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

        strategy = new StrategyUniEthUsdtLpV3(
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

        // Set time
        hevm.warp(startTime);
    }

    function _getWant(uint256 ethAmount, uint256 daiAmount) internal {
        _getERC20(usdt, daiAmount);

        uint256 _usdt = IERC20(usdt).balanceOf(address(this));
        USDT(usdt).approve(address(univ2), _usdt);

        univ2.addLiquidityETH{value: ethAmount}(
            usdt,
            _usdt,
            0,
            0,
            address(this),
            now + 60
        );
    }

    // **** Tests ****

    function test_ethusdtv3_timelock() public {
        assertTrue(strategy.timelock() == timelock);
        strategy.setTimelock(address(1));
        assertTrue(strategy.timelock() == address(1));
    }

    function test_ethusdtv3_withdraw_release() public {
        _getWant(10 ether, 4000e6); // WANT w/ 10 ETH and 400 DAI in 18 decimals
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).approve(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.warp(block.timestamp + 1 weeks);
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

    function test_ethusdtv3_get_earn_harvest_rewards() public {
        _getWant(10 ether, 4000e6); // WANT w/ 10 ETH and 400 DAI in 18 decimals
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).approve(address(pickleJar), _want);
        pickleJar.deposit(_want);
        pickleJar.earn();
        hevm.warp(block.timestamp + 1 weeks);

        // Call the harvest function
        uint256 _before = pickleJar.balance();
        uint256 _treasuryBefore = IERC20(want).balanceOf(treasury);
        strategy.harvest();
        uint256 _after = pickleJar.balance();
        uint256 _treasuryAfter = IERC20(want).balanceOf(treasury);

        uint256 earned = _after.sub(_before).mul(1000).div(970);
        uint256 earnedRewards = earned.mul(45).div(1000); // 4.5%
        uint256 actualRewardsEarned = _treasuryAfter.sub(_treasuryBefore);

        // 4.5% performance fee is given
        assertEqApprox(earnedRewards, actualRewardsEarned);

        // Withdraw
        uint256 _devBefore = IERC20(want).balanceOf(devfund);
        _treasuryBefore = IERC20(want).balanceOf(treasury);
        uint256 _stratBal = strategy.balanceOf();
        pickleJar.withdrawAll();
        uint256 _devAfter = IERC20(want).balanceOf(devfund);
        _treasuryAfter = IERC20(want).balanceOf(treasury);

        // 0.125% goes to dev
        uint256 _devFund = _devAfter.sub(_devBefore);
        assertEq(_devFund, _stratBal.mul(125).div(100000));

        // 0.375% goes to treasury
        uint256 _treasuryFund = _treasuryAfter.sub(_treasuryBefore);
        assertEq(_treasuryFund, _stratBal.mul(375).div(100000));
    }
}
