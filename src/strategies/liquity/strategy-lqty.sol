// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/lqty-staking.sol";
import "../../interfaces/weth.sol";

contract StrategyLqty is StrategyBase {
    // Token addresses
    address public lqty_staking = 0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d;

    address public lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address public lqty = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public lusd_pool = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    
    uint24 public constant poolFee = 3000;

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

    function getName() external override pure returns (string memory) {
        return "StrategyLqty";
    }

    function harvest() public override onlyBenevolent {
        ILiquityStaking(lqty_staking).unstake(0);
        uint256 _lusd = IERC20(lusd).balanceOf(address(this));

        if (_lusd > 0) {
            IERC20(lusd).safeApprove(lusd_pool, 0);
            IERC20(lusd).safeApprove(lusd_pool, _lusd);

            // Swap to USDC because it's consistently the heaviest weighted 3pool token
            ICurveFi_4(lusd_pool).exchange_underlying(0, 2, _lusd, 0);
        }
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        if (_usdc > 0) {
            IERC20(usdc).safeApprove(univ3Router, 0);
            IERC20(usdc).safeApprove(univ3Router, _usdc);

            ISwapRouter(univ3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(usdc, poolFee, weth, poolFee, lqty),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _usdc,
                    amountOutMinimum: 0
                })
            );
        }
        _distributePerformanceFeesAndDeposit();
    }

    function balanceOfPool() public override view returns (uint256) {
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
