// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxLinkELp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_link_lp_rewards = 0x2e10D9d08f76807eFdB6903025DE8e006b1185F5;
    address public png_avax_link_lp = 0x5875c368Cddd5FB9Bf2f410666ca5aad236DAbD4;
    address public link = 0x5947BB275c521040051D82396192181b413227A3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            link,
            png_avax_link_lp_rewards,
            png_avax_link_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxLinkELp";
    }
}
