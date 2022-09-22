// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloEthSethSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xFd7FddFc0A729eCF45fB6B12fA3B71A575E1966F;
    address private _gauge = 0x101D5e5651D7f949154258C1C7516da1eC273476;
    address private constant seth = 0xE405de8F52ba7559f9df3C368500B6E6ae6Cee49;

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
        nativeToTokenRoutes[seth].push(ISolidlyRouter.route(native, seth, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloEthSethSlp";
    }
}
