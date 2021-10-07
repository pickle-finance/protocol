pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyConvexCvxCrv is StrategyConvexFarmBase {
    address public lpToken = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;
    uint256 public cvxcrvPoolId = 41;
    address public pool = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            cvxcrvPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCvxCrv";
    }

    function get_cvx_earned() public view override returns (uint256 cvxRewards) {
        address cvxRewardsContract = IBaseRewardPool(getCrvRewardContract())
            .extraRewards(0);
        cvxRewards = IBaseRewardPool(cvxRewardsContract).earned(address(this));
    }

    function getHarvestable() public view returns (uint256, uint256) {
        return (get_crv_earned(), get_cvx_earned());
    }

    function harvest() public override onlyBenevolent {

        IBaseRewardPool(getCrvRewardContract()).getReward(address(this), true);

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));

        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            uint256[2] memory amounts = [_crv, 0];
            IERC20(crv).safeApprove(pool, 0);
            IERC20(crv).safeApprove(pool, _crv);
            ICurveFi_4(pool).add_liquidity(amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
