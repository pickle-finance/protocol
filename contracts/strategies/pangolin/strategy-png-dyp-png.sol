// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngDypPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_dyp_png_lp_rewards = 0x3A0eF6a586D9C15de30eDF5d34ae00E26b0125cE;
    address public png_dyp_png_lp = 0x3EB6109CbD142e1b4b0Ef1706D92B64628048062;
    address public dyp = 0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            dyp,
            png_dyp_png_lp_rewards,
            png_dyp_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngDypPngLp";
    }
}
