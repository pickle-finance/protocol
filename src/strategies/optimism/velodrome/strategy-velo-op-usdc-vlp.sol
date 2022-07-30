// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./strategy-velo-base.sol";

contract StrategyVeloOpUsdcVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x47029bc8f5CBe3b464004E87eF9c9419a48018cd;
    address private _gauge = 0x0299d40E99F2a5a1390261f5A71d13C3932E214C;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant op = 0x4200000000000000000000000000000000000042;

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
        isStablePool = false;

        // token0 route
        nativeToTokenRoutes[op].push(RouteParams(native, op, false));

        // token1 route
        nativeToTokenRoutes[usdc].push(RouteParams(native, usdc, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloOpUsdcVlp";
    }
}
