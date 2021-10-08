// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngXavaPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_xava_png_lp_rewards =
        0x5b3Ed7f47D1d4FA22b559D043a09d78bc55A94E9;
    address public png_xava_png_lp = 0x851D47BE09BD0D3c2B24922e34a4f8AE05456924;
    address public xava = 0xd1c3f94DE7e5B45fa4eDBBA472491a9f4B166FC4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            xava,
            png_xava_png_lp_rewards,
            png_xava_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngXavaPngLp";
    }
}
