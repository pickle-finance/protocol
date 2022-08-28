// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcAgeurVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x7866C6072B09539fC0FDE82963846b80203d7beb;
    address private _gauge = 0x97f7884C1e57cA991B949B9aC2c6A04599e8F988;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant ageur = 0x9485aca5bbBE1667AD97c7fE7C4531a624C8b1ED;

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
        nativeToTokenRoutes[usdc].push(ISolidlyRouter.route(native, usdc, false));

        // token1 route
        nativeToTokenRoutes[ageur].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[ageur].push(ISolidlyRouter.route(usdc, ageur, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcAgeurVlp";
    }
}
