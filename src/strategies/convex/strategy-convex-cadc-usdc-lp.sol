pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyConvexCadcUsdc is StrategyConvexFarmBase {
    address public lpToken = 0x1054Ff2ffA34c055a13DCD9E0b4c0cA5b3aecEB9;
    uint256 public crvEthPoolId = 79;
    address public pool = 0xE07BDe9Eb53DEFfa979daE36882014B758111a78;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyConvexFarmBase(lpToken, crvEthPoolId, _governance, _strategist, _controller, _timelock) {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCadcUsdc";
    }

    function getHarvestable() public view returns (uint256, uint256) {
        return (get_crv_earned(), get_cvx_earned());
    }

    function harvest() public override onlyBenevolent {
        (uint256 _crvHarvestable, uint256 _cvxHarvestable) = getHarvestable();

        if (_crvHarvestable > 0 || _cvxHarvestable > 0)
            IBaseRewardPool(getCrvRewardContract()).getReward(address(this), true);

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, usdc, _cvx);
        }

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, usdc, _crv);
        }

        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        if (_usdc > 0) {
            uint256[2] memory amounts = [0, _usdc];
            IERC20(usdc).safeApprove(pool, 0);
            IERC20(usdc).safeApprove(pool, _usdc);
            ICurveFi_2(pool).add_liquidity(amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
