// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngGdlPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_gdl_png_lp_rewards = 0xb008e7AD32c710B07fb8D4453aBC79214Cd34891;
    address public png_gdl_png_lp = 0xB852E8D27AB836F142DFb1509eA6cA281b24CB73;
    address public gdl = 0xD606199557c8Ab6F4Cc70bD03FaCc96ca576f142;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            gdl,
            png_gdl_png_lp_rewards,
            png_gdl_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngGdlPngLp";
    }
}
