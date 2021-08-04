// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngYfiPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_yfi_png_rewards = 0xc7D0E29b616B29aC6fF4FD5f37c8Da826D16DB0D;
    address public png_yfi_png_lp = 0xa465e953F9f2a00b2C1C5805560207B66A570093;
	address public yfi = 0x99519AcB025a0e0d44c3875A4BbF03af65933627;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            yfi,
            png_yfi_png_rewards,
            png_yfi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngYfiPngLp";
    }
}	