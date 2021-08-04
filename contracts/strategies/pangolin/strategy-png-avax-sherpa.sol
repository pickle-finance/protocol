// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxSherpaLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_sherpa_lp_rewards = 0x99918c92655D6f8537588210cD3Ddd52312CB36d;
    address public png_avax_sherpa_lp = 0xD27688e195B5495a0eA29Bb6e9248E535A58511e;
    address public sherpa = 0xa5E59761eBD4436fa4d20E1A27cBa29FB2471Fc6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            sherpa,
            png_avax_sherpa_lp_rewards,
            png_avax_sherpa_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxSherpaLp";
    }
}
