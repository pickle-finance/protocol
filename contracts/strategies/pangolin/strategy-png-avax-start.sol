// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxStartLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_start_lp_rewards = 0x5105d9De003fB7d22979cd0cE167Ab919E60900A;
    address public png_avax_start_lp = 0x8d0BfC06AF725CFaA38672b97c9fFaAD16081aF9;
    address public start = 0xF44Fb887334Fa17d2c5c0F970B5D320ab53eD557;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            start,
            png_avax_start_lp_rewards,
            png_avax_start_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxStartLp";
    }
}
