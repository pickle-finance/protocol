// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngHuskyPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_husky_png_lp_rewards = 0x07b34dAABcb75C9cbD0c8AEfbC0ed5E30845eF12;
    address public png_husky_png_lp = 0x93E5a0DA3BE1052c32fd1a04449607F75bDB05c8;
    address public husky = 0x65378b697853568dA9ff8EaB60C13E1Ee9f4a654;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            husky,
            png_husky_png_lp_rewards,
            png_husky_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngHuskyPngLp";
    }
}
