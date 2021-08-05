// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngAavePngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_aave_png_lp_rewards = 0x3F91756D773A1455A7a1A70f5d9239F1B1d1f095;
    address public png_aave_png_lp = 0x11Bc32032002146Cb65Ab391dF5B51682A8d7885;
    address public aave = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            aave,
            png_aave_png_lp_rewards,
            png_aave_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAavePngLp";
    }
}
