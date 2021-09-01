// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxGdlLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_gdl_lp_rewards = 0xA6F2408e3CD34084c37A0D88FED8C6b6490F7529;
    address public png_avax_gdl_lp = 0xc5AB0C94Bc88b98f55f4e21C1474F67ab2329CFD;
    address public gdl = 0xD606199557c8Ab6F4Cc70bD03FaCc96ca576f142;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            gdl,
            png_avax_gdl_lp_rewards,
            png_avax_gdl_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxGdlLp";
    }
}
