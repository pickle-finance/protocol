// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloEthOpVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xcdd41009E74bD1AE4F7B2EeCF892e4bC718b9302;
    address private _gauge = 0x2f733b00127449fcF8B5a195bC51Abb73B7F7A75;
    address private constant op = 0x4200000000000000000000000000000000000042;

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
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloEthOpVlp";
    }
}
