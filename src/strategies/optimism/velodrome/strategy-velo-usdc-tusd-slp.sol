// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcTusdSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xA4549B89A39f76d9D28415474aeD7d06Ec9935fe;
    address private _gauge = 0xc4eAB0D1d7616eA99c15698bb075C2Adb8D2fDc5;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant tusd = 0xcB59a0A753fDB7491d5F3D794316F1adE197B21E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyVeloBase(
            _lp,
            _gauge,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        isStablePool = true;

        // token0 route
        nativeToTokenRoutes[usdc].push(ISolidlyRouter.route(native, usdc, false));

        // token1 route
        nativeToTokenRoutes[tusd].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[tusd].push(ISolidlyRouter.route(usdc, tusd, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcTusdSlp";
    }
}
