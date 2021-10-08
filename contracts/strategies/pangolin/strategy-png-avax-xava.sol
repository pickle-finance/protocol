// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxXavaLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_xava_lp_rewards =
        0x4219330Af5368378D5ffd869a55f5F2a26aB898c;
    address public png_avax_xava_lp =
        0x42152bDD72dE8d6767FE3B4E17a221D6985E8B25;
    address public xava = 0xd1c3f94DE7e5B45fa4eDBBA472491a9f4B166FC4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            xava,
            png_avax_xava_lp_rewards,
            png_avax_xava_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxXavaLp";
    }
}
