pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyConvexCvxCrv is StrategyConvexFarmBase {

    // Token addresses
    address public cvxcrv = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address public three_crv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    address public rewards = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    
    // Curve pools
    address public threePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public cvxPool = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            cvxcrv,
            0, // not used
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCvxCrv";
    }

    function balanceOfPool() public view override returns (uint256) {
        return IBaseRewardPool(rewards).balanceOf(address(this));
    }

    function get_crv_earned() public view override returns (uint256) {
        return IBaseRewardPool(rewards).earned(address(this));
    }

    function get_three_crv_earned() public view returns (uint256) {
        return
            IVirtualBalanceRewardPool(IBaseRewardPool(rewards).extraRewards(0))
                .earned(address(this));
    }

    function getHarvestable()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (get_crv_earned(), get_cvx_earned(), get_three_crv_earned());
    }

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);

            IBaseRewardPool(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBaseRewardPool(rewards).withdraw(_amount, false);
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        IBaseRewardPool(rewards).getReward();

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));

        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }

        // Exchange 3crv to USDC
        uint256 _three_crv = IERC20(three_crv).balanceOf(address(this));
        if (_three_crv > 0) {
            IERC20(three_crv).safeApprove(threePool, 0);
            IERC20(three_crv).safeApprove(threePool, _three_crv);
            ICurveZap(threePool).remove_liquidity_one_coin(_three_crv, 1, 0);
        }

        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        if (_usdc > 0) {
            IERC20(usdc).safeApprove(sushiRouter, 0);
            IERC20(usdc).safeApprove(sushiRouter, _usdc);
            _swapSushiswap(usdc, crv, _usdc);
        }

        // Exchange all CRV for cvxCRV
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(cvxPool, 0);
            IERC20(crv).safeApprove(cvxPool, _crv);
            ICurveFi_2(cvxPool).exchange(0, 1, _crv, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
