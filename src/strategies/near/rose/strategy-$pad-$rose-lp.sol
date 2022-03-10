// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-lp.sol";

contract StrategyPadRoseLp is StrategyRoseFarmLPBase {
    // Token addresses
    address public pad_rose_rewards =
        0x9b2aE7d53099Ec64e2f6df3B4151FFCf7205f788;
    address public pad_pad_rose_lp = 0xC6C3cc84EabD4643C382C988fA2830657fc70a6B;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmLPBase(
            pad_rose_rewards,
            pad_pad_rose_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadRoseLp";
    }
}
