// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxWowLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_wow_lp_rewards =
        0x437352a8e2394379521bc84f0874c66c94f32fbb;
    address public png_avax_wow_lp = 0x5085678755446f839b1b575cb3d1b6ba85c65760;
    address public wow = 0xa384bc7cdc0a93e686da9e7b8c0807cd040f4e0b;

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
