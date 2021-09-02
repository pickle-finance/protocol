// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../strategy-base.sol";

contract StrategyFraxDaiUniV3 is StrategyBase {
    address public strategyProxy;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(lqty, _governance, _strategist, _controller, _timelock)
    {}

    // **** Views ****

    //for test only
    function setStrategyProxy(address _proxy) external {
        strategyProxy = _proxy;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyFraxDaiUniV3";
    }

    function harvest() public override onlyBenevolent {
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);
            _swapUniswap(weth, lqty, _weth);
        }
        _distributePerformanceFeesAndDeposit();
    }

    function balanceOfPool() public view override returns (uint256) {
        return ILiquityStaking(lqty_staking).stakes(address(this));
    }

    function getHarvestable() public view returns (uint256, uint256) {
        return (
            ILiquityStaking(lqty_staking).getPendingLUSDGain(address(this)),
            ILiquityStaking(lqty_staking).getPendingETHGain(address(this))
        );
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(star, 0);
            IERC20(want).safeApprove(lqty_staking, _want);
            ILiquityStaking(lqty_staking).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ILiquityStaking(lqty_staking).unstake(_amount);
        return _amount;
    }
}
