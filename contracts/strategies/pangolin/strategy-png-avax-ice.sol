// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxIceLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_ice_lp_rewards =
        0x12b493a6e4f185ef1feef45565654f71156c25ba;
    address public png_avax_ice_lp = 0x24df88626312d37b1cbb46d2e0491477d1bec84a;
    address public ice = 0xfc108f21931576a21d0b4b301935dac80d9e5086;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            ice,
            png_avax_ice_lp_rewards,
            png_avax_ice_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxIceLp";
    }
}
