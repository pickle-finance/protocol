// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-raider-farm-base.sol";

contract StrategyRaiderMaticLp is StrategyRaiderFarmBase {
    // Token addresses
    address public raider_matic_lp = 0x2E7d6490526C7d7e2FDEa5c6Ec4b0d1b9F8b25B7;
    address public raider_matic_rewards = 0x3d5099B13Eb4334618dF7D16A211EAF2bb5b780c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRaiderFarmBase(
            raider_matic_lp,
            raider_matic_rewards,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyRaiderMaticLp";
    }
}
