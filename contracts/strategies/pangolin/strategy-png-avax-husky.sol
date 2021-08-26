// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxHuskyLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_husky_lp_rewards = 0x2e60ab79BbCdfea164874700D5d98969a386eB2a;
    address public png_avax_husky_lp = 0xd05e435Ae8D33faE82E8A9E79b28aaFFb54c1751;
    address public husky = 0x65378b697853568dA9ff8EaB60C13E1Ee9f4a654;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            husky,
            png_avax_husky_lp_rewards,
            png_avax_husky_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxHuskyLp";
    }
}
