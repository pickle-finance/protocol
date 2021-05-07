// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-yearn-affiliate.sol";

contract StrategyYearnCrvSteth is StrategyYearnAffiliate {
    // Token addresses
    address public crv_steth_lp = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address public yearn_registry = 0x3eE41C098f9666ed2eA246f4D2558010e59d63A0

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyYearnAffiliate(
            crv_steth_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyYearnCrvSteth";
    }
}
