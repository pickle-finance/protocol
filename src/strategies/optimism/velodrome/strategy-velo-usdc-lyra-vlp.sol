// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcLyraVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xDEE1856D7B75Abf4C1bDf986da4e1C6c7864d640;
    address private _gauge = 0x461ba7FA5c2e94EB93e881b7C7E3A7DC4c1CD6b4;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant lyra = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;

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

        // token1 route
        nativeToTokenRoutes[lyra].push(RouteParams(native, usdc, false));
        nativeToTokenRoutes[lyra].push(RouteParams(usdc, lyra, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcLyraVlp";
    }
}
