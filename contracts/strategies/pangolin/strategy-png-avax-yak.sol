// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxYakLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_yak_lp_rewards = 0xb600429CCD364F1727F91FC0E75D67d65D0ee4c5;
    address public png_avax_yak_lp = 0xd2F01cd87A43962fD93C21e07c1a420714Cc94C9;
    address public yak = 0x59414b3089ce2AF0010e7523Dea7E2b35d776ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            yak,
            png_avax_yak_lp_rewards,
            png_avax_yak_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxYakLp";
    }
}
