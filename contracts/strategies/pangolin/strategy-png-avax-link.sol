// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxLinkLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_link_lp_rewards = 0xBDa623cDD04d822616A263BF4EdbBCe0B7DC4AE7;
    address public png_avax_link_lp = 0xbbC7fFF833D27264AaC8806389E02F717A5506c9;
    address public link = 0xB3fe5374F67D7a22886A0eE082b2E2f9d2651651;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            link,
            png_avax_link_lp_rewards,
            png_avax_link_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxLinkLp";
    }
}
