// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./strategy-velo-base.sol";

contract StrategyVeloEthUsdcVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x79c912FEF520be002c2B6e57EC4324e260f38E50;
    address private _gauge = 0xE2CEc8aB811B648bA7B1691Ce08d5E800Dd0a60a;
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
        nativeToTokenRoutes[usdc].push(RouteParams(native, usdc, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloEthUsdcVlp";
    }
}
