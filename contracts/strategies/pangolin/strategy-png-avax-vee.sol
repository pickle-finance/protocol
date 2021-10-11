// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxVeeLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_vee_lp_rewards =
        0xDa959F3464FE2375f0B1f8A872404181931978B2;
    address public png_avax_vee_lp = 0xd69De4d5FF6778b59Ff504d7d09327B73344Ff10;
    address public vee = 0x3709E8615E02C15B096f8a9B460ccb8cA8194e86;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            vee,
            png_avax_vee_lp_rewards,
            png_avax_vee_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxVeeLp";
    }
}
