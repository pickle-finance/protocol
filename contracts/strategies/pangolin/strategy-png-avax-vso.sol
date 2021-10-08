// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxVsoLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_vso_lp_rewards =
        0xf2b788085592380bfCAc40Ac5E0d10D9d0b54eEe;
    address public png_avax_vso_lp = 0x2b532bC0aFAe65dA57eccFB14ff46d16a12de5E6;
    address public vso = 0x846D50248BAf8b7ceAA9d9B53BFd12d7D7FBB25a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            vso,
            png_avax_vso_lp_rewards,
            png_avax_vso_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxVsoLp";
    }
}
