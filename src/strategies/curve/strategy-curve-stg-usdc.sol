// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-curve-base-v2.sol";

contract StrategyCurveStgUsdc is StrategyCurveBaseV2 {
    // Curve stuff
    address public stg_usdc_pool = 0x3211C6cBeF1429da3D0d58494938299C92Ad5860;
    address public stg_usdc_gauge = 0x95d16646311fDe101Eb9F897fE06AC881B7Db802;
    address public stg_usdc = 0xdf55670e27bE5cDE7228dD0A6849181891c9ebA1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCurveBaseV2(stg_usdc_pool, stg_usdc_gauge, stg_usdc, _governance, _strategist, _controller, _timelock)
    {
        IERC20(crv).safeApprove(sushiRouter, uint256(-1));
        IERC20(usdc).safeApprove(curve, uint256(-1));

        swapRoutes[usdc] = [crv, weth, usdc];
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurveStgUsdc";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        ICurveGauge(gauge).claim_rewards(address(this));

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            IERC20(crv).safeTransfer(IController(controller).treasury(), _keepCRV);

            _crv = IERC20(crv).balanceOf(address(this));
            _swapSushiswapWithPath(swapRoutes[usdc], _crv);
        }

        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        // Adds liquidity to curve.fi's pool
        if (_usdc > 0) {
            IERC20(usdc).safeApprove(curve, uint256(-1));
            uint256[3] memory liquidity;
            liquidity[2] = _usdc;
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
