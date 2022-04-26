// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-curve-base.sol";

contract StrategyCurveStgUsdc is StrategyCurveBase {
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
        StrategyCurveBase(stg_usdc_pool, stg_usdc_gauge, stg_usdc, _governance, _strategist, _controller, _timelock)
    {
        IERC20(crv).safeApprove(sushiRouter, uint256(-1));
        IERC20(usdc).safeApprove(curve, uint256(-1));
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurveStgUsdc";
    }

    function getMostPremium() public view override returns (address, uint256) {
        return (address(0), 0);
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        ICurveMintr(mintr).mint(gauge);

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            IERC20(crv).safeTransfer(IController(controller).treasury(), _keepCRV);

            address[] memory route = new address[](3);
            route[0] = crv;
            route[1] = weth;
            route[2] = usdc;

            _crv = IERC20(crv).balanceOf(address(this));

            _swapSushiswap(crv, usdc, _crv.div(2));
        }

        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        // Adds liquidity to curve.fi's pool
        if (_usdc > 0) {
            uint256[2] memory liquidity;
            liquidity[1] = _usdc;
            ICurveFi_2(curve).add_liquidity(liquidity, 0);
        }

        deposit();
    }
}
