// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngSushiPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_sushi_png_rewards = 0x633F4b4DB7dD4fa066Bd9949Ab627a551E0ecd32;
    address public png_sushi_png_lp = 0xF105fb50fC6DdD8a857bbEcd296c8a630E8ca857;
	address public sushi = 0x39cf1BD5f15fb22eC3D9Ff86b0727aFc203427cc;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            sushi,
            png_sushi_png_rewards,
            png_sushi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngSushiPngLp";
    }
}	