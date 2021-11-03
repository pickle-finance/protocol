// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-teddy-base.sol";

contract StrategyTeddyxTeddy is StrategyTeddyBase {
    // Token addresses
    address public stake_teddy_rewards =
        0xb4387D93B5A9392f64963cd44389e7D9D2E1053c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTeddyBase(
            stake_teddy_rewards,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTeddyxTeddy";
    }
}
