// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngSnobPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_snob_png_rewards = 0x08B9A023e34Bad6Db868B699fa642Bf5f12Ebe76;
    address public png_snob_png_lp = 0x97B4957df08E185502A0ac624F332c7f8967eE8D;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            snob,
            png_snob_png_rewards,
            png_snob_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngSnobPngLp";
    }
}
