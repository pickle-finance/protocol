// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngBnbPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_bnb_png_rewards = 0x68a90C38bF4f90AC2a870d6FcA5b0A5A218763AD;
    address public png_bnb_png_lp = 0x76BC30aCdC88b2aD2e8A5377e59ed88c7f9287f9;
	address public bnb = 0x264c1383EA520f73dd837F915ef3a732e204a493;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            bnb,
            png_bnb_png_rewards,
            png_bnb_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngBnbPngLp";
    }
}