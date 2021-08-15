// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngYakPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_yak_png_rewards = 0x42ff9473a5AEa00dE39355e0288c7A151EB00B6e;
    address public png_yak_png_lp = 0x42c45fE57927AB94f5BA5484483B67184aA82e5d;
    address public yak = 0x59414b3089ce2AF0010e7523Dea7E2b35d776ec7;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            yak,
            png_yak_png_rewards,
            png_yak_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngYakPngLp";
    }
}	