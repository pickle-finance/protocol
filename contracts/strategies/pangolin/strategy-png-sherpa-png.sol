// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngSherpaPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_sherpa_png_lp_rewards = 0x80E919784e7c5AD3Dd59cAfCDC0e9C079B65f262;
    address public png_sherpa_png_lp = 0x3DCC9711558115bFB73db19E8326cD717F6E5540;
    address public sherpa = 0xa5E59761eBD4436fa4d20E1A27cBa29FB2471Fc6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            sherpa,
            png_sherpa_png_lp_rewards,
            png_sherpa_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngSherpaPngLp";
    }
}
