// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base.sol";

contract StrategyRoseFraxLp is StrategyRoseFarmLPBase {
    // Token addresses
    address public rose_frax_rewards = 0x1B10bFCd6192edC573ced7Db7c7e403c7FAb8068;
    address public pad_rose_frax_lp = 0xeD4C231b98b474f7cAeCAdD2736e5ebC642ad707;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmLPBase(
            rose_frax_rewards,
            pad_rose_frax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyRoseFraxLp";
    }
}
