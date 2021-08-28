// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngQiPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_qi_png_lp_rewards = 0x2bD42C357a3e13F18849C67e8dC108Cc8462ae33;
    address public png_qi_png_lp = 0x50E7e19281a80E3C24a07016eDB87EbA9fe8C6cA;
    address public qi = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            qi,
            png_qi_png_lp_rewards,
            png_qi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngQiPngLp";
    }
}
