// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngEthPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_eth_png_rewards = 0x7ac007afB5d61F48D1E3C8Cc130d4cf6b765000e;
    address public png_eth_png_lp = 0x53B37b9A6631C462d74D65d61e1c056ea9dAa637;
	address public eth = 0xf20d962a6c8f70c731bd838a3a388D7d48fA6e15;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            eth,
            png_eth_png_rewards,
            png_eth_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngEthPngLp";
    }
}	