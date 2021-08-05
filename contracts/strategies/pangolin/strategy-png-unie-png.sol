// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngUniEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_uni_png_lp_rewards = 0xD4E49A8Ec23daB51ACa459D233e9447DE03AFd29;
    address public png_uni_png_lp = 0x792828974273725A7027da1C2341f4162e17174b;
    address public uni = 0x8eBAf22B6F053dFFeaf46f4Dd9eFA95D89ba8580;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            uni,
            png_uni_png_lp_rewards,
            png_uni_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngUniEPngLp";
    }
}
