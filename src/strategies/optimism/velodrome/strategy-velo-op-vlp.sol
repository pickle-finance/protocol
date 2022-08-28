// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloOpVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xFFD74EF185989BFF8752c818A53a47FC45388F08;
    address private _gauge = 0x1F36f95a02C744f2B3cD196b5e44E749c153D3B9;
    address private constant op = 0x4200000000000000000000000000000000000042;
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
        nativeToTokenRoutes[op].push(ISolidlyRouter.route(native, op, false));

        // token1 route
        nativeToTokenRoutes[velo].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[velo].push(ISolidlyRouter.route(usdc, velo, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloOpVlp";
    }
}
