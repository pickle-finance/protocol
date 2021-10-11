// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxOoeLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_ooe_lp_rewards =
        0xB9cE09322FC55Da298e27b8678d300423988b40E;
    address public png_avax_ooe_lp = 0xE44Ef634A6Eca909eCb0c73cb371140DE85357F9;
    address public ooe = 0x0ebd9537A25f56713E34c45b38F421A1e7191469;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            ooe,
            png_avax_ooe_lp_rewards,
            png_avax_ooe_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxOoeLp";
    }
}
