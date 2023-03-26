// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloWstethSethSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xB343dae0E7fe28c16EC5dCa64cB0C1ac5F4690AC;
    address private _gauge = 0xB30EAC66C790178438667aB220C98Cc983D77383;
    address private constant wsteth = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
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

        // token0 route
        nativeToTokenRoutes[wsteth].push(ISolidlyRouter.route(native, wsteth, false));

        // token1 route
        nativeToTokenRoutes[seth].push(ISolidlyRouter.route(native, seth, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloWstethSethSlp";
    }
}
