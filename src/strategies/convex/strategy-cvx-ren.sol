pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyConvexRenCRV is StrategyConvexFarmBase {
    // Curve stuff
    address public ren_pool = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    uint256 public cvx_pool_id = 6;
    address public lpToken = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
	
    // bitcoins
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCurveBase(
            ren_pool,
            cvx_pool_id,
            lpToken,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getMostPremium()
        public
        override
        view
        returns (address, uint256)
    {
       // Both 8 decimals, so doesn't matter
        uint256[] memory balances = new uint256[](2);
        balances[0] = ICurveFi_2(curve).balances(0); // RENBTC
        balances[1] = ICurveFi_2(curve).balances(1); // WBTC

        // renbtc
        if (balances[0] < balances[1]) {
            return (renbtc, 0);
        }

        // WBTC
        if (balances[1] < balances[0]) {
            return (wbtc, 1);
        }

        // If they're somehow equal, we just want RENBTC
        return (renbtc, 0);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyConvexRenCRV";
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
			
        // input token we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, to, _cvx);
        }
		
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, to, _crv);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (crvRenWBTC)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[2] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_2(curve).add_liquidity(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
