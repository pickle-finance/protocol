// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloEthAlethSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x6fD5BEe1Ddb4dbBB0b7368B080Ab99b8BA765902;
    address private _gauge = 0xEF9A5fF5d3057d539543Bc223efCcbc2168b19D6;
    address private constant aleth = 0x3E29D3A9316dAB217754d13b28646B76607c5f04;

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

        // token1 route
        nativeToTokenRoutes[aleth].push(ISolidlyRouter.route(native, aleth, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloEthAlethSlp";
    }
}
