// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cometh-farm-base.sol";

contract StrategyComethPickleMustLpV4 is StrategyComethFarmBase {
    // Token addresses
    address public cometh_rewards = 0x52f68A09AEe9503367bc0cda0748C4D81807Ae9a;
    address public cometh_pickle_must_lp = 0xb0b5E3Bd18eb1E316bcD0bBa876570b3c1779C55;
    address public pickle = 0x2b88aD57897A8b496595925F43048301C37615Da;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyComethFarmBase(
            cometh_rewards,
            cometh_wmatic_must_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyComethPickleMustLpV4";
    }
}
