// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcAlusdSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xe75a3f4Bf99882aD9f8aeBAB2115873315425D00;
    address private _gauge = 0x1d87cee5C2F88B60588dD97E24D4B7c3d4f74935;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant alusd = 0xCB8FA9a76b8e203D8C3797bF438d8FB81Ea3326A;

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
        nativeToTokenRoutes[usdc].push(RouteParams(native, usdc, false));

        // token1 route
        nativeToTokenRoutes[alusd].push(RouteParams(native, usdc, false));
        nativeToTokenRoutes[alusd].push(RouteParams(usdc, alusd, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcAlusdSlp";
    }
}
