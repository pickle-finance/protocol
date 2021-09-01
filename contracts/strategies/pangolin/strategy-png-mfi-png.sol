// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngMfiPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_mfi_png_lp_rewards = 0x4c0650668A63EF468c7bDCd910A62287e9FC4d52;
    address public png_mfi_png_lp = 0x334Fd3526D5F55301FF3faa0fc231d38FA45e342;
    address public mfi = 0x9Fda7cEeC4c18008096C2fE2B85F05dc300F94d0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            mfi,
            png_mfi_png_lp_rewards,
            png_mfi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngMfiPngLp";
    }
}
