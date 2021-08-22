// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-fox-farm-base.sol";

contract StrategyFoxEthFoxLp is StrategyFoxFarmBase {
    // Token addresses
    address public fox_eth_fox_lp = 0x470e8de2eBaef52014A47Cb5E6aF86884947F08c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFoxFarmBase(
            fox,
            fox_eth_fox_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyFoxEthFoxLp";
    }
}
