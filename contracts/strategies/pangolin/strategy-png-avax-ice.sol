// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxIceLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_ice_lp_rewards =
        0x12b493A6E4F185EF1feef45565654F71156C25bA;
    address public png_avax_ice_lp = 0x24dF88626312D37b1cBb46d2e0491477D1bEc84a;
    address public ice = 0xfC108f21931576a21D0b4b301935DAc80d9E5086;

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
