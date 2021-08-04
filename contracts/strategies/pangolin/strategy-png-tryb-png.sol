// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngTrybPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_tryb_png_lp_rewards = 0x0A9773AEbc1429d860A492d70c8EA335fAa9F19f;
    address public png_tryb_png_lp = 0x471163B54b5db0497cd9eAFCb1b53CC569d71B76;
    address public tryb = 0x564A341Df6C126f90cf3ECB92120FD7190ACb401;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            tryb,
            png_tryb_png_lp_rewards,
            png_tryb_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngTrybPngLp";
    }
}
