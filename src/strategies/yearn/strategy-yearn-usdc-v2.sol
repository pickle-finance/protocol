// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-yearn-affiliate.sol";

contract StrategyYearnUsdcV2 is StrategyYearnAffiliate {
    // Token addresses
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyYearnAffiliate(
            usdc,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}
