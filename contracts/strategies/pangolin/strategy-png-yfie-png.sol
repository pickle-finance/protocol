// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngYfiEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_yfi_png_lp_rewards = 0x269Ed6B2040f965D9600D0859F36951cB9F01460;
    address public png_yfi_png_lp = 0x32Db611163CB2243E43d61D7721EBAa0226e8e08;
    address public yfi = 0x9eAaC1B23d935365bD7b542Fe22cEEe2922f52dc;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            yfi,
            png_yfi_png_lp_rewards,
            png_yfi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngYfiEPngLp";
    }
}
