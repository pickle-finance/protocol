pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyCrvEth is StrategyConvexFarmBase {
    address public lpToken = 0xEd4064f376cB8d68F770FB1Ff088a3d0F3FF5c4d;
    uint256 public crvEthPoolId = 61;
    address public pool = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            crvEthPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyCrvEth";
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

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            uint256[2] memory amounts = [0, _crv];
            IERC20(crv).safeApprove(pool, 0);
            IERC20(crv).safeApprove(pool, _crv);
            ICurveFi_2(pool).add_liquidity(amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
