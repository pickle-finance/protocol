// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngWbtcEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_wbtc_png_lp_rewards = 0xEeEA1e815f12d344b5035a33da4bc383365F5Fee;
    address public png_wbtc_png_lp = 0xf277e270bc7664E6EBba19620530b83883748a13;
    address public wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            wbtc,
            png_wbtc_png_lp_rewards,
            png_wbtc_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngWbtcEPngLp";
    }
}
