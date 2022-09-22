// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-velo-base.sol";

contract StrategyVeloEthAlienVlp is StrategyVeloBase {
    // Addresses
    address private _lp = 0x3EEc44e94ee86ce79f34Bb26dc3CdbbEe18d6d17;
    address private _gauge = 0xAF307D86B08C54Bb840Ab17ef66AbBBA87C6aaBe;
    address private constant alien = 0x61BAADcF22d2565B0F471b291C475db5555e0b76;

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
        nativeToTokenRoutes[alien].push(ISolidlyRouter.route(native, alien, false));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyVeloEthAlienVlp";
    }
}
