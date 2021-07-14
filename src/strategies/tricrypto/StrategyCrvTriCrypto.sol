pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyCrvTriCrypto is StrategyConvexFarmBase {
    address public lpToken = 0xcA3d75aC011BF5aD07a98d02f18225F9bD9A6BDF;
    uint256 public crvTricryptoPoolId = 37;
    address public pool = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            crvTricryptoPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyCrvTriCrypto";
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
            _swapSushiswap(cvx, weth, _cvx);
        }
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, weth, _crv);
        }

        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            uint256[3] memory amounts;
            amounts[0] = 0;
            amounts[1] = 0;
            amounts[2] = _weth;
            IERC20(weth).safeApprove(pool, 0);
            IERC20(weth).safeApprove(pool, _weth);
            ICurveFi_3(pool).add_liquidity(amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
