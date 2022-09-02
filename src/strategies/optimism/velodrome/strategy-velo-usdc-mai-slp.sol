// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcMaiSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xd62C9D8a3D4fd98b27CaaEfE3571782a3aF0a737;
    address private _gauge = 0xDF479E13E71ce207CE1e58D6f342c039c3D90b7D;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant mai = 0xdFA46478F9e5EA86d57387849598dbFB2e964b02;

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
        nativeToTokenRoutes[mai].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[mai].push(ISolidlyRouter.route(usdc, mai, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcMaiSlp";
    }
}
