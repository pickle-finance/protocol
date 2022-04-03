// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-yearn-affiliate.sol";

contract StrategyYearnCrvIB is StrategyYearnAffiliate {
    // Token addresses
    address public crv_ib_lp = 0x5282a4eF67D9C33135340fB3289cc1711c13638C;
    address public yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyYearnAffiliate(
            crv_ib_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}
