// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-raider-farm-base.sol";

contract StrategyAurumMaticLp is StrategyRaiderFarmBase {
    // Token addresses
    address public aurum_matic_lp = 0x91670a2A69554c61d814CD7f406D7793387E68Ef;
    address public aurum_matic_rewards = 0x831F618595bE796FC0e0c2c1B405Ed2fEbEBFDeC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRaiderFarmBase(
            aurum_matic_lp,
            aurum_matic_rewards,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAurumMaticLp";
    }
}
