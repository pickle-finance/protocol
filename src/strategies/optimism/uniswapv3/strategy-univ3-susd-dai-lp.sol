// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategySusdDaiUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0xAdb35413eC50E0Afe41039eaC8B930d313E94FA4;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        performanceTreasuryFee = 1000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategySusdDaiUniV3Optimism";
    }
}
