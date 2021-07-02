// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngUniPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_uni_png_rewards = 0x4f74BbF6859A994e7c309eA0f11E3Cc112955110;
    address public png_uni_png_lp = 0x874685bc6794c8b4bEFBD037147C2eEF990761A9;
	address public uni = 0xf39f9671906d8630812f9d9863bBEf5D523c84Ab;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            uni,
            png_uni_png_rewards,
            png_uni_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngUniPngLp";
    }
}	