// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPng<token>PngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_<token>_png_lp_rewards = <rewards>;
    address public png_<token>_png_lp = <lp>;
    address public <token> = <token_addr>;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            <token>,
            png_<token>_png_lp_rewards,
            png_<token>_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPng<token>PngLp";
    }
}
