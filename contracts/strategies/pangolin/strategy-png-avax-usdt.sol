// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxUsdtLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_usdt_lp_rewards = 0x94C021845EfE237163831DAC39448cFD371279d6;
    address public png_avax_usdt_lp = 0x9EE0a4E21bd333a6bb2ab298194320b8DaA26516;
    address public usdt = 0xde3A24028580884448a5397872046a019649b084;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            usdt,
            png_avax_usdt_lp_rewards,
            png_avax_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxUsdtLp";
    }
}
