// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngUsdcEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_usdc_png_lp_rewards = 0x73d1cC4B8dA555005E949B3ECEE490A7206C14DF;
    address public png_usdc_png_lp = 0xC33Ac18900b2f63DFb60B554B1F53Cd5b474d4cd;
    address public usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            usdc,
            png_usdc_png_lp_rewards,
            png_usdc_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngUsdcEPngLp";
    }
}
