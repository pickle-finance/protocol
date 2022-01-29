// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-raider-farm-base.sol";

contract StrategyRaiderWethLp is StrategyRaiderFarmBase {
    // Token addresses
    address public raider_weth_lp = 0x426a56F6923c2B8A488407fc1B38007317ECaFB1;
    address public raider_weth_rewards = 0xCbD0CC751808911A96014629d53f5441dD6c80e0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRaiderFarmBase(
            raider_weth_lp,
            raider_weth_rewards,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyRaiderWethLp";
    }
}
