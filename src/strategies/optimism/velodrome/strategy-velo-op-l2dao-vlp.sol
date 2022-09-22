// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloOpL2daoVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0xfc77e39De40E54F820E313039207DC850E4C9E60;
    address private _gauge = 0xB4d9036B81b9B6A7De1C70887c29938eC8df6048;
    address private constant l2dao = 0xd52f94DF742a6F4B4C8b033369fE13A41782Bf44;
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

        // token1 route
        nativeToTokenRoutes[l2dao].push(ISolidlyRouter.route(native, op, false));
        nativeToTokenRoutes[l2dao].push(ISolidlyRouter.route(op, l2dao, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloOpL2daoVlp";
    }
}
