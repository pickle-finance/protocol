// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategySusdUsdcUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x8EdA97883a1Bc02Cf68C6B9fb996e06ED8fDb3e5;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {}

    function getName() external pure override returns (string memory) {
        return "StrategySusdUsdcUniV3Optimism";
    }
}
