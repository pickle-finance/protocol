// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngTusdPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_tusd_png_lp_rewards = 0x6fa49bd916e392dc9264636b0b5Cf2beee652dA3;
    address public png_tusd_png_lp = 0x829fB5203fB2420fe71d977E884658d030564FA4;
    address public tusd = 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            tusd,
            png_tusd_png_lp_rewards,
            png_tusd_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngTusdPngLp";
    }
}
