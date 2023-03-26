// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloEthRethVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x985612ff2C9409174FedcFf23d4F4761AF124F88;
    address private _gauge = 0x89C1a33011Fab92e497963a6FA069aEE5c1f5D44;
    address private constant reth = 0x9Bcef72be871e61ED4fBbc7630889beE758eb81D;

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

        // token1 route
        nativeToTokenRoutes[reth].push(ISolidlyRouter.route(native, reth, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloEthRethVlp";
    }
}
