// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxMyakLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_myak_lp_rewards =
        0x716c19807f46F97DdAc0745878675fF5B3A75004;
    address public png_avax_myak_lp =
        0xBccebf064b8FcC0CB4DF6c5d15F9F6fEaD3Df88d;
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
