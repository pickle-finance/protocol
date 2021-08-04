// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngUsdtPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_usdt_png_rewards = 0xE2510a1fCCCde8d2D1c40b41e8f71fB1F47E5bBA;
    address public png_usdt_png_lp = 0xE8AcF438B10A2C09f80aEf3Ef2858F8E758C98F9;
	address public usdt = 0xde3A24028580884448a5397872046a019649b084;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            usdt,
            png_usdt_png_rewards,
            png_usdt_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngUsdtPngLp";
    }
}	