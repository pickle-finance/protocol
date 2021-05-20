// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-yearn-v1-affiliate.sol";

contract StrategyYearnCrvEurs is StrategyYearnV1Affiliate {
    // Token addresses
    address public crv_eurs_lp = 0x194eBd173F6cDacE046C53eACcE9B953F28411d1;
    address public vault = 0x98B058b2CBacF5E99bC7012DF757ea7CFEbd35BC;

    constructor(
        address _controller,
        address _timelock
    )
        public
        StrategyYearnV1Affiliate(
            crv_eurs_lp,
            vault,
            _controller,
            _timelock
        )
    {}
}
