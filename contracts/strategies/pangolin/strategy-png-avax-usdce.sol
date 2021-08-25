// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxUsdcELp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_usdc_lp_rewards = 0x84B536dA1A2D9b0609f9Da73139674cc2D75AF2D;
    address public png_avax_usdc_lp = 0xbd918Ed441767fe7924e99F6a0E0B568ac1970D9;
    address public usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            usdc,
            png_avax_usdc_lp_rewards,
            png_avax_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxUsdcELp";
    }
}
