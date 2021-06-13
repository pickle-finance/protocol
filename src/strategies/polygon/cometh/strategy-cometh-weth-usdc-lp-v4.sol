// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cometh-farm-base.sol";

contract StrategyComethWethUsdcLpV4 is StrategyComethFarmBase {
    // Token addresses
    address public cometh_rewards = 0x1c30Cfe08506BA215c02bc2723C6D310671BAb62;
    address public cometh_weth_usdc_lp = 0x1Edb2D8f791D2a51D56979bf3A25673D6E783232;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyComethFarmBase(
            cometh_rewards,
            cometh_weth_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyComethWethUsdcLpV4";
    }
}
