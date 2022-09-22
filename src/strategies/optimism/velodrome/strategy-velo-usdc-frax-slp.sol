// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcFraxSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xAdF902b11e4ad36B227B84d856B229258b0b0465;
    address private _gauge = 0x14d60F07924e3a7226DDD368409243eDF87e6205;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant frax = 0x2E3D870790dC77A83DD1d18184Acc7439A53f475;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVeloBase(
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
        nativeToTokenRoutes[frax].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[frax].push(ISolidlyRouter.route(usdc, frax, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcFraxSlp";
    }
}
