// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngWalbtPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_walbt_png_lp_rewards = 0x393fe4bc29AfbB3786D99f043933c49097449fA1;
    address public png_walbt_png_lp = 0x29117b9C78DB238725Df08E40D3507DCAaf67713;
    address public walbt = 0x9E037dE681CaFA6E661e6108eD9c2bd1AA567Ecd;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            walbt,
            png_walbt_png_lp_rewards,
            png_walbt_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngWalbtPngLp";
    }
}
