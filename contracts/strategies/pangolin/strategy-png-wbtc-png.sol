// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngWbtcPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_wbtc_png_rewards = 0x681047473B6145BA5dB90b074E32861549e85cC7;
    address public png_wbtc_png_lp = 0xf372ceAE6B2F4A2C4A6c0550044A7eab914405ea;
	address public wbtc = 0x408D4cD0ADb7ceBd1F1A1C33A0Ba2098E1295bAB;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            wbtc,
            png_wbtc_png_rewards,
            png_wbtc_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngWbtcPngLp";
    }
}	