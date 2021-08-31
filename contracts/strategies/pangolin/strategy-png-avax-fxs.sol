// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxFxsLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_fxs_lp_rewards = 0x76Ad5c64Fe6B26b6aD9aaAA19eBa00e9eCa31FE1;
    address public png_avax_fxs_lp = 0xd538a741c6782Cf4E21e951cdA39327c50C51087;
    address public fxs = 0xD67de0e0a0Fd7b15dC8348Bb9BE742F3c5850454;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            fxs,
            png_avax_fxs_lp_rewards,
            png_avax_fxs_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxFxsLp";
    }
}
