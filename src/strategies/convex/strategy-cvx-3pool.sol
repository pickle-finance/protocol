pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

contract StrategyConvex3CRV is StrategyConvexFarmBase {
    address public three_pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    uint256 public cvx_pool_id = 9;
    address public lpToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
	
    // stablecoins
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCurveBase(
            three_pool,
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
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_3(curve).balances(2).mul(10**12); // USDT

        // DAI
        if (
            balances[0] < balances[1] &&
            balances[0] < balances[2]
        ) {
            return (dai, 0);
        }

        // USDC
        if (
            balances[1] < balances[0] &&
            balances[1] < balances[2]
        ) {
            return (usdc, 1);
        }

        // USDT
        if (
            balances[2] < balances[0] &&
            balances[2] < balances[1]
        ) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyConvex3CRV";
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
        // to get back want (3crv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
