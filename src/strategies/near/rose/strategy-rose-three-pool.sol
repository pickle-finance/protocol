// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-stable.sol";

contract StrategyRoseThreePool is StrategyRoseFarmStableBase {
    // Token addresses
    address public three_pool_rewards = 0x52CACa9a2D52b27b28767d3649565774A3B991f3;
    address public three_pool_lp = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmStableBase(
            three_pool_rewards,
            three_pool_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyRoseThreePool";
    }
}
