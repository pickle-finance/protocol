// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../../lib/erc20.sol";
import "../../../lib/safe-math.sol";

import "../../../interfaces/jar.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";
import "../../../interfaces/controller.sol";

import "./strategy-curve-base.sol";

contract StrategyCurveTricrypto is StrategyCurveBase {
    // Curve stuff
    address private _pool = 0x960ea3e3C7FB317332d990873d354E18d7645590;
    address private _gauge = 0x555766f3da968ecBefa690Ffd49A2Ac02f47aa5f;
    address private _want = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;

    address public swaprRouter = 0x530476d5583724A89c8841eB6Da76E7Af4C0F17E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyCurveBase(_pool, _gauge, _want, _governance, _strategist, _controller, _timelock) {
        sushiRouter = swaprRouter; // Best liquidity for CRV
        IERC20(crv).safeApprove(sushiRouter, type(uint256).max);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurveTricrypto";
    }

    // **** State Mutations ****

    function harvest() public override {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.
        ICurveMintr(mintr).mint(gauge);

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            _swapSushiswap(crv, weth, _crv);
        }
        _distributePerformanceFeesNative();

        uint256 _weth = IERC20(weth).balanceOf(address(this));
        // Adds liquidity to curve.fi's pool
        if (_weth > 0) {
            uint256[3] memory liquidity;
            liquidity[2] = _weth;
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        deposit();
    }
}
