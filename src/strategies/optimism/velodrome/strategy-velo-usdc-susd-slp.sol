// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcSusdSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xd16232ad60188B68076a235c65d692090caba155;
    address private _gauge = 0xb03f52D2DB3e758DD49982Defd6AeEFEa9454e80;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant susd = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;

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
        nativeToTokenRoutes[susd].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[susd].push(ISolidlyRouter.route(usdc, susd, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcSusdSlp";
    }
}
