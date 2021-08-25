// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxDypLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_dyp_lp_rewards = 0x29a7F3D1F27637EDA531dC69D989c86Ab95225D8;
    address public png_avax_dyp_lp = 0x497070e8b6C55fD283D8B259a6971261E2021C01;
    address public dyp = 0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            dyp,
            png_avax_dyp_lp_rewards,
            png_avax_dyp_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxDypLp";
    }
}
