// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xe8537b6FF1039CB9eD0B71713f697DDbaDBb717d;
    address private _gauge = 0x6b8EDC43de878Fd5Cd5113C42747d32500Db3873;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

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
        nativeToTokenRoutes[velo].push(RouteParams(native, velo, false));

        // token1 route
        nativeToTokenRoutes[usdc].push(RouteParams(native, usdc, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcVlp";
    }
}
