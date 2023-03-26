// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcDolaSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x6C5019D345Ec05004A7E7B0623A91a0D9B8D590d;
    address private _gauge = 0xAFD2c84b9d1cd50E7E18a55e419749A6c9055E1F;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant dola = 0x8aE125E8653821E851F12A49F7765db9a9ce7384;

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
        nativeToTokenRoutes[dola].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[dola].push(ISolidlyRouter.route(usdc, dola, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcDolaSlp";
    }
}
