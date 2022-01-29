pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyCvxEth is StrategyConvexFarmBase {
    address public lpToken = 0x3A283D9c08E8b55966afb64C515f5143cf907611;
    uint256 public cvxEthPoolId = 64;
    address public pool = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            cvxEthPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyCvxEth";
    }

    function getHarvestable() public view returns (uint256, uint256) {
        return (get_crv_earned(), get_cvx_earned());
    }

    function harvest() public override onlyBenevolent {
        (uint256 _crvHarvestable, uint256 _cvxHarvestable) = getHarvestable();

        if (_crvHarvestable > 0 || _cvxHarvestable > 0)
            IBaseRewardPool(getCrvRewardContract()).getReward(
                address(this),
                true
            );

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, cvx, _crv);
        }
        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            uint256[2] memory amounts = [0, _cvx];
            IERC20(cvx).safeApprove(pool, 0);
            IERC20(cvx).safeApprove(pool, _cvx);
            ICurveFi_2(pool).add_liquidity(amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
