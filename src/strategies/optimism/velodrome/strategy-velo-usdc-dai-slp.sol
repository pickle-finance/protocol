// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcDaiSlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x4F7ebc19844259386DBdDB7b2eB759eeFc6F8353;
    address private _gauge = 0xc4fF55A961bC04b880e60219CCBBDD139c6451A4;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

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
        nativeToTokenRoutes[dai].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[dai].push(ISolidlyRouter.route(usdc, dai, true));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcDaiSlp";
    }
}
