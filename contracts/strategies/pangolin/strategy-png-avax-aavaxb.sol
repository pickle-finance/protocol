// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxAavaxBLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_aavaxb_lp_rewards =
        0xAa01F80375528F36291677C683905b4A113A6470;
    address public png_avax_aavaxb_lp =
        0xAa9A58792CBFA3DE9Cef36a5CF0E3608a6a106B7;
    address public aavaxb = 0x6C6f910A79639dcC94b4feEF59Ff507c2E843929;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            aavaxb,
            png_avax_aavaxb_lp_rewards,
            png_avax_aavaxb_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxAavaxBLp";
    }
}
