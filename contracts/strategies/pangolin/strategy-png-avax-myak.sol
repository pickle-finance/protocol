// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxMyakLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_myak_lp_rewards =
        0xb600429CCD364F1727F91FC0E75D67d65D0ee4c5;
    address public png_avax_myak_lp =
        0xbccebf064b8fcc0cb4df6c5d15f9f6fead3df88d;
    address public myak = 0xdDAaAD7366B455AfF8E7c82940C43CEB5829B604;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            myak,
            png_avax_myak_lp_rewards,
            png_avax_myak_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxMyakLp";
    }
}
