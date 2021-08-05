// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngLinkPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_link_png_lp_rewards = 0x4B283e4211B3fAa525846d21869925e78f93f189;
    address public png_link_png_lp = 0x340d732f44E2Fb8D08719883f1C2ae088EB11682;
    address public link = 0x5947BB275c521040051D82396192181b413227A3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            link,
            png_link_png_lp_rewards,
            png_link_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngLinkPngLp";
    }
}
