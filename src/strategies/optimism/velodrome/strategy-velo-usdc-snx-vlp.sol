// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloUsdcSnxVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x9056EB7Ca982a5Dd65A584189994e6a27318067D;
    address private _gauge = 0x099b3368eb5BBE6f67f14a791ECAeF8bC1628A7F;
    address private constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private constant snx = 0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4;

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
        isStablePool = false;

        // token0 route
        nativeToTokenRoutes[usdc].push(ISolidlyRouter.route(native, usdc, false));

        // token1 route
        nativeToTokenRoutes[snx].push(ISolidlyRouter.route(native, usdc, false));
        nativeToTokenRoutes[snx].push(ISolidlyRouter.route(usdc, snx, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloUsdcSnxVlp";
    }
}
