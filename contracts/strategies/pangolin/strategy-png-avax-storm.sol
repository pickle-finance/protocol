// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxStormLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_storm_lp_rewards = 0x62Da43b98a9338221cc36dDa40605B0F5eA0Ac2d;
    address public png_avax_storm_lp = 0x9613Acd03dcb6Ee2a03546dD7992d7DF2aa62d9a;
    address public storm = 0x6AFD5A1ea4b793CC1526d6Dc7e99A608b356eF7b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            storm,
            png_avax_storm_lp_rewards,
            png_avax_storm_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxStormLp";
    }
}
