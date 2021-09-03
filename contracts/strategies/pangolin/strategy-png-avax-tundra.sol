// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxTundraLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_tundra_lp_rewards = 0xeD617a06C6c727827Ca3B6fb3E565C68342c4c2b;
    address public png_avax_tundra_lp = 0x0a081F54d81095D9F8093b5F394Ec9b0EF058876;
    address public tundra = 0x21c5402C3B7d40C89Cc472C9dF5dD7E51BbAb1b1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            tundra,
            png_avax_tundra_lp_rewards,
            png_avax_tundra_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxTundraLp";
    }
}
