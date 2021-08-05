// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxWbtcLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_wbtc_lp_rewards = 0x30CbF11f6fcc9FC1bF6E55A6941b1A47A56eAEC5;
    address public png_avax_wbtc_lp = 0x5764b8D8039C6E32f1e5d8DE8Da05DdF974EF5D3;
    address public wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            wbtc,
            png_avax_wbtc_lp_rewards,
            png_avax_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxWbtcLp";
    }
}
