// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxTusdLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_tusd_lp_rewards = 0xf2dd964AcF53ad8959540CceEFD9FeA13d4D0Eb1;
    address public png_avax_tusd_lp = 0xE9DfCABaCA5E45C0F3C151f97900511f3E73Fb47;
    address public tusd = 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            tusd,
            png_avax_tusd_lp_rewards,
            png_avax_tusd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxTusdLp";
    }
}
