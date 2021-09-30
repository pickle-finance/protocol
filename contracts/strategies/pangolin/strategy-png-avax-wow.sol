// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxWowLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_wow_lp_rewards =
        0x437352A8E2394379521BC84f0874c66c94F32fbb;
    address public png_avax_wow_lp = 0x5085678755446F839B1B575cB3d1b6bA85C65760;
    address public wow = 0xA384Bc7Cdc0A93e686da9E7B8C0807cD040F4E0b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            wow,
            png_avax_wow_lp_rewards,
            png_avax_wow_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxWowLp";
    }
}
