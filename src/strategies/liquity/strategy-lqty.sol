// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/lqty-staking.sol";
import "../../interfaces/weth.sol";

contract StrategyLqty is StrategyBase {
    // Token addresses
    address public lqty_staking = 0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d;

    address public lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address public lqty = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;

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

    function getName() external pure override returns (string memory) {
        return "StrategyLqty";
    }

    function harvest() public override onlyBenevolent {
        ILiquityStaking(lqty_staking).unstake(0);
        uint256 _lusd = IERC20(lusd).balanceOf(address(this));

        if (_lusd > 0) {
            IERC20(lusd).safeApprove(univ2Router2, 0);
            IERC20(lusd).safeApprove(univ2Router2, _lusd);

            _swapUniswap(lusd, weth, _lusd);
        }
        uint256 _eth = address(this).balance;
        if (_eth > 0) {
            WETH(weth).deposit{value: _eth}();
        }
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
            IERC20(want).safeApprove(lqty_staking, 0);
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

    receive() external payable {}
}
