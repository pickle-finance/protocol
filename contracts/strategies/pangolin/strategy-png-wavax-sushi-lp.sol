// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxSushiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_rewards = 0x8Cc0183526ab00b2b1F3f4d42Ae7821e6Af2CbCb;
    address public png_avax_sushi_lp = 0x8364a01108D9b71Ed432C63Ba7fa57236A908647;
    address public sushi = 0xf4E0A9224e8827dE91050b528F34e2F99C82Fbf6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            sushi,
            png_rewards,
            png_avax_sushi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxSushiLp";
    }
}
