// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-stake-png-farm-base.sol";

contract StrategyPngXPng is StrategyStakePngFarmBase {
    // Token addresses
    address public stake_png_rewards = 0xD49B406A7A29D64e081164F6C3353C599A2EeAE9;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakePngFarmBase(
            stake_png_rewards,
            png,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngXPng";
    }
}	