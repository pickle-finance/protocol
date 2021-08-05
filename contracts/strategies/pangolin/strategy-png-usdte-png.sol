// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngUsdtEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_usdt_png_lp_rewards = 0x7216d1e173c1f1Ed990239d5c77d74714a837Cd5;
    address public png_usdt_png_lp = 0x1fFB6ffC629f5D820DCf578409c2d26A2998a140;
    address public usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            usdt,
            png_usdt_png_lp_rewards,
            png_usdt_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngUsdtEPngLp";
    }
}
