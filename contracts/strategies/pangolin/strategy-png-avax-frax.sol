// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxFraxLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_frax_lp_rewards =
        0x55152E05202AE58fDab26b20c6Fd762F5BCA797c;
    address public png_avax_frax_lp =
        0x0CE543c0f81ac9AAa665cCaAe5EeC70861a6b559;
    address public frax = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            frax,
            png_avax_frax_lp_rewards,
            png_avax_frax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxFraxLp";
    }
}
