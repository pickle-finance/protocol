// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../../lib/erc20.sol";
import "../../../lib/safe-math.sol";

import "../../../interfaces/jar.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";
import "../../../interfaces/controller.sol";

import "./strategy-curve-base.sol";

contract StrategyCurveAm3CRVv2 is StrategyCurveBase {
    // Curve stuff
    address public three_pool = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    address public three_gauge = 0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c;
    address public three_crv = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCurveBase(
            three_pool,
            three_gauge,
            three_crv,
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
        balances[0] = ICurveFi_Polygon_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_Polygon_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_Polygon_3(curve).balances(2).mul(10**12); // USDT

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
        return "StrategyCurve3CRVv2";
    }

    // **** State Mutations ****

    function harvest() public onlyBenevolent override {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        ICurveGauge(gauge).claim_rewards(address(this));

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            IERC20(crv).safeApprove(univ2Router2, 0);
            IERC20(crv).safeApprove(univ2Router2, _crv);
            _swapUniswap(crv, to, _crv);
        }

        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            IERC20(wmatic).safeApprove(univ2Router2, 0);
            IERC20(wmatic).safeApprove(univ2Router2, _wmatic);

            _swapUniswap(wmatic, to, _wmatic);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_Polygon_3(curve).add_liquidity(liquidity, 0, true);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
