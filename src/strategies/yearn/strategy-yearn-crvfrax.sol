// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-yearn-affiliate.sol";

contract StrategyYearnCrvFrax is StrategyYearnAffiliate {
    // Token addresses
    address public crv_frax_lp = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public yearn_registry = 0x3eE41C098f9666ed2eA246f4D2558010e59d63A0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyYearnAffiliate(
            crv_frax_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}
