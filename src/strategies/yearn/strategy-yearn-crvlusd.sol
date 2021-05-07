// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-yearn-affiliate.sol";

contract StrategyYearnCrvLusd is StrategyYearnAffiliate {
    // Token addresses
    address public crv_lusd_lp = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address public yearn_registry = 0x3eE41C098f9666ed2eA246f4D2558010e59d63A0

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

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyYearnCrvLusd";
    }
}
